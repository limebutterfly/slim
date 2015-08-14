require "base64"
require 'zlib'

module MzXML
  class Spectrum
    attr_accessor :m_z, :int, :msLevel, :precursorMass, :retentionTime

    def self.decompress data, method
      case method
        when 'zlib'
          return Zlib::Inflate.inflate data
        when 'none'
          return data
        else
          raise 'Cant decode spectrum data with unknown compression type %s.'%compressionType
      end
    end

    def self.fromXML xml
      if xml =~ /\<peaks /
        #extract features
        msLevel=$1.to_i if xml =~/msLevel="(\d+)"/
        retentionTime=$1.to_f if xml =~ /retentionTime="P?T?(\d+.\d+)S?"/
        compressionType='none'
        compressionType=$1 if xml =~ /compressionType="(\w+)"/
        precision=64
        precision=$1.to_i if xml =~ /precision="(\d+)"/
        byteOrder='network'
        byteOrder=$1 if xml =~ /byteOrder="(\w+)"/
        data=$1 if xml =~ /\<peaks[^\>]*\>([A-Za-z0-9+\/]+=*)\<\/peaks\>/m
        raise 'no data found in peaks table' if data.nil?
        return self.new data: data, byteOrder: byteOrder, precision: precision, compressionType: compressionType, retentionTime: retentionTime, msLevel: msLevel
      elsif xml =~ /\<binaryDataArray/
        msLevel=$1.to_i if xml =~ /\<cvParam cvRef="MS" accession="[^"]*" name="ms level" value="(\d)"\/\>/
        precision=64
        precision=$1.to_i if xml=~ /\<cvParam cvRef="MS" accession="[^"]*" name="(\d+)-bit float"/
        compressionType='none'
        compressionType='zlib' if xml =~ /name="zlib compression"/
        precursorMass=$1.to_f if xml=~ /\<cvParam cvRef="MS" accession="[^"]*" name="selected ion m\/z" value="(\d+.\d*)" /
        m_z=$1 if xml=~ /\<cvParam cvRef="MS" accession="[^"]*" name="m\/z array"[^\>]*\/\>[^>]*\<binary\>([A-Za-z0-9+\/]+=*)\<\/binary\>/m
        int=$1 if xml=~ /\<cvParam cvRef="MS" accession="[^"]*" name="intensity array"[^\>]*\/\>[^>]*\<binary\>([A-Za-z0-9+\/]+=*)\<\/binary\>/m
        retentionTime=$1.to_f if xml =~ /\<cvParam cvRef="MS" accession="[^"]*" name="scan start time" value="(\d+\.\d+)"/
        raise 'no m_z array found in spectrum' if m_z.nil?
        raise 'no intensity array found in spectrum' if int.nil?
        return self.new int:int, m_z: m_z, msLevel: msLevel, precision:precision, compressionType:compressionType, retentionTime: retentionTime, precursorMass: precursorMass
      else
        raise 'did not recognize spectrum type'
      end
    end

    def initialize data: nil, m_z: nil, int: nil, precision: 64, byteOrder: 'network', compressionType: 'zlib', msLevel: 1, retentionTime: nil, precursorMass: nil
      raise 'no spectrum to decode' if data.nil? and (m_z.nil? or int.nil?)
      raise 'decide if you want to have data or mz/int separate' if !data.nil? and !(m_z.nil? or int.nil?)
      case precision
        when 64, '64'
          data_format = 'G*'
        when 32, '32'
          data_format = 'g*'
        else
          raise 'Cant decode spectrum data with unknown precision %s.'%(precision.to_s)
      end
      raise 'Cant decode spectrum data with unkown byte order %s.'%byteOrder unless byteOrder=='network'
      @msLevel = msLevel.nil? ? nil : msLevel.to_i
      @retentionTime = retentionTime.nil? ? nil : retentionTime.to_f
      @precursorMass = precursorMass.nil? ? nil: precursorMass.to_f
      unless data.nil?
        data = self.class.decompress Base64.decode64(data),compressionType
        data = data.unpack data_format
        dataPoints = data.length
        raise 'cant decode spectrum data: Spectrum data dataPoints not multiple of two (m/z - intensity).' unless dataPoints%2==0
        @m_z = []
        @int = []
        dataPoints.times do |i|
          if i%2==0
            @m_z.push data[i]
          else
            @int.push data[i]
          end
        end
        @dataPoints = dataPoints/2
      else
        int = self.class.decompress Base64.decode64(int), compressionType
        m_z = self.class.decompress Base64.decode64(m_z), compressionType
        @int = int.unpack data_format
        @m_z = m_z.unpack data_format
        raise 'm/z and intensity arrays do not have the same length (m/z=%i points, intensity=%i points)'%[@int.length,@m_z.length] unless @int.length==@m_z.length
        @dataPoints = @m_z.length
      end
    end

    def search m_z, tolerance: nil, ppm: nil #tolerance in m_z, ppm in ppm
      raise 'cant specify tolerance AND ppm simultaneously in spectrum search' unless ppm.nil? or tolerance.nil?
      if tolerance.nil?
        if ppm.nil?
          tolerance = 0
        else
          tolerance = ppm.to_f / 1000000
        end
      else
        tolerance = tolerance.to_f
      end
      index = []
      @dataPoints.times do |i|
        if @m_z[i] <= m_z+tolerance
          index.push i
          next
        end
        if @m_z[i] >= m_z-tolerance
          index.push i
        end
      end
      return index
    end

    def intensity(m_z, tolerance: nil, ppm:nil)
      index = search m_z, tolerance: tolerance, ppm: ppm
      return nil if index.length == 0
      return @int[index[0]] if index.length == 1
      int = 0
      index.each do |i|
        int = @int[i] if @int[i]>int
      end
      return int
    end

    def points(cutoff: 0, log: nil, start: nil,stop: nil)
      cutoff = log^cutoff unless log.nil?
      points_array = []
      @dataPoints.times do |i|
        next if !start.nil? and @m_z[i]<start
        next if !stop.nil? and @m_z[i]>stop
        next if @int[i] < cutoff
        if log.nil?
          intensity = @int[i]
        else
          intensity = intensity==0 ? nil : log(intensity,log)
        end
        points_array.push [@m_z[i],intensity]
      end
      return points_array
    end

  end
end