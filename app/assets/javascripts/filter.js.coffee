# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


heatmap = (value, min, max) ->
  r = (value-min)/(max-min)
  if r<0.5
    d = Math.floor(256*r+127)
    'rgb('+d+','+d+',255)'
  else
    d = Math.floor(255+255*(0.5-r))
    'rgb(255,'+d+','+d+')'

$(document).ready ->
  norm = false
  results = []
  sorting_criterium = 'n_ids'
  draw_row = () ->
    this.empty()
    if this.data.is_oxifeature && not this.data.has_id
      this.append('<td>through oxichain</td>')
    else
      this.append('<td><a href="'+this.data.lipid_url.url+'">'+this.data.lipid.common_name+'</a></td>')
    this.append('<td><a href="'+this.data.feature_url.url+'">'+this.data.feature.id_string+'</a></td>')
    switch sorting_criterium
      when 'n_ids' then this.append('<td>'+this.data.n_ids+'</td>')
      when 'cat'
        unless this.data.is_oxifeature && not this.data.has_id
          this.append('<td>'+this.data.lipid.main_class+'</td>')
        else
          this.append('<td>&nbsp;</td>')
      when 'oxidations'
        unless this.data.is_oxifeature && not this.data.has_id
          this.append('<td>'+this.data.lipid.oxidations+'</td>')
        else
          this.append('<td></td>')
      when 'rt' then this.append('<td>'+this.data.feature.rt+'</td>')
      when 'm/z' then this.append('<td>'+this.data.feature.m_z+'</td>')
      when 'oxichain' then this.append('<td>'+this.data.feature.oxichain+'</td>')
      else this.append('<td>???</td>')
    values = []
    for i in [0..this.data.values.length/2-1]
      if norm
        values.push this.data.values[i*2+1]
      else
        values.push this.data.values[i*2]
    ma = Math.max.apply(Math,values);
    mi = Math.min.apply(Math,values);
    for i in values
      if norm
        this.append($("<td />", html:Math.floor(i) ).css('background-color',heatmap(i,mi,ma)))
      else
        this.append($("<td />", html:Math.floor(i) ).css('background-color',heatmap(i,mi,ma)))
  export_csv = () ->
    csv = ''
    header = ['feature',
              'retention_time',
              'm/z',
              'lipid',
              'common_name',
              'oxidations',
              'score',
              'fragmentation_score',
              'mass_error',
              'isotope_similarity',
              'category',
              'main_class',
              'sub_class',
              'n_identifications',
              'included_by_oxichain',
              'oxichain']
    csv += header.join(',')+($('#sample_names').html())+"\n"
    for row in results
      d = row.data
      r = []
      r.push d.feature.id_string
      r.push d.feature.rt
      r.push d.feature.m_z
      unless d.is_oxifeature && not d.has_id
        r.push d.lipid.common_name
        r.push d.lipid.lm_id
        r.push d.lipid.oxidations
        r.push d.identification.score
        r.push d.identification.fragmentation_score
        r.push d.identification.mass_error
        r.push d.identification.isotope_similarity
        r.push d.lipid.category_
        r.push d.lipid.main_class
        r.push d.lipid.sub_class
        r.push d.n_ids
        if d.is_oxifeature
          r.push 'true'
        else
          r.push 'false'
      else
        r.push 'through oxichain' #common_name
        r.push '' #lm_id
        r.push '' #noxidations
        r.push '' #id_score
        r.push '' # id_fragscore
        r.push '' #mass_error
        r.push ''  #iss
        r.push 'oxichain' #category
        r.push '' #main
        r.push '' #subclass
        r.push 0 #n_ids
        r.push true  #oxifeature
      r.push d.feature.oxichain
      for i in [0..d.values.length/2-1]
        r.push d.values[i*2]
      for i in [0..d.values.length/2-1]
        r.push d.values[i*2+1]
      csv += "\""+r.join('","')+"\"\n"
    window.open(encodeURI('data:application/csv;charset=utf-8;filename=results.csv,'+csv))


  if $( "#results" ).length
    $.ajax 'get_list.json', success: (data) ->
      $("#waiting").remove()
      for d in data.ids
        row = $('<tr />', id: 'result_'+d.id)
        row.data = d
        row.draw_row = draw_row
        row.draw_row()
        results.push row
        $("#results").append(row)
      for d in data.oxifeatures
        row = $('<tr />', id: 'feature_'+d.id)
        row.data = d
        row.draw_row = draw_row
        row.draw_row()
        results.push row
        $("#results").append(row)
      $("#info").html '<br /><p>Filtered '+(data.length)+' lipids.</p>'
      $("#info").append $('<button />', class:'btn btn-default filter-button', text: 'show normalized values', id: 'toggle_norm').click((e) ->
        if norm
          # switch to raw values
          norm = false
          $('#toggle_norm').text 'show normalized values'
          $('.values_norm').hide()
          $('.values_raw').show()
        else
          # switch to normalized values
          norm = true
          $('#toggle_norm').text 'show raw values'
          $('.values_norm').show()
          $('.values_raw').hide()
        for row in results
          row.draw_row()
      )
      $("#info").append $('<button />', class:'btn btn-default filter-button', text: 'sort by category').click((e) ->
        cat = {}
        $('#sorting_criterium').html('Category')
        sorting_criterium = 'cat'
        for row in results
          row.detach()
          cat[row.data.lipid.main_class] ||= []
          cat[row.data.lipid.main_class].push row
        for key, value of cat
          value.sort (a,b) ->
            if a.data.lipid.oxidations >= b.data.lipid.oxidations
              return 1
            else
              return -1
          for row in value
            $("#results").append(row)
            row.draw_row()
      )
      $("#info").append $('<button />', class:'btn btn-default filter-button', text: 'sort by oxidations').click((e) ->
        cat = {}
        for i in [0..10]
          cat[i] = []
        $('#sorting_criterium').html('Oxidations')
        sorting_criterium = 'oxidations'
        for row in results
          row.detach()
          cat[row.data.lipid.oxidations].push row
        for key, value of cat
          for row in value
            $("#results").append(row)
            row.draw_row()
      )
      $("#info").append $('<button />', class:'btn btn-default filter-button', text: 'sort by retention time').click((e) ->
        $('#sorting_criterium').html('rt (min)')
        sorting_criterium = 'rt'
        results = results.sort (a,b) ->
          if a.data.feature.rt >= b.data.feature.rt
            return 1
          else
            return -1
        for row in results
          row.detach()
          row.draw_row()
          $("#results").append(row)
      )
      $("#info").append $('<button />', class:'btn btn-default filter-button', text: 'sort by m/z').click((e) ->
        $('#sorting_criterium').html('m/z')
        sorting_criterium = 'm/z'
        results = results.sort (a,b) ->
          if a.data.feature.m_z >= b.data.feature.m_z
            return 1
          else
            return -1
        for row in results
          row.detach()
          row.draw_row()
          $("#results").append(row)
      )
      $("#info").append $('<button />', class:'btn btn-default filter-button', text: 'sort by oxichain').click((e) ->
        $('#sorting_criterium').html('oxichain #')
        sorting_criterium = 'oxichain'
        results = results.sort (a,b) ->
          if a.data.feature.oxichain == b.data.feature.oxichain
            if a.data.feature.m_z >= b.data.feature.m_z
              return 1
            else
              return -1
          if a.data.feature.oxichain >= b.data.feature.oxichain
            return 1
          else
            return -1
        for row in results
          row.detach()
          row.draw_row()
          $("#results").append(row)
      )
      $("#info").append $('<button />', class:'btn btn-default filter-button', text: 'download as csv').click((e) ->
        export_csv()
      )
    $('.values_norm').hide()
  if $("#statistics").length
    $("#statistics").html $('<button>',text: 'load statistics',click: (e) ->
      $("#statistics").html('loading statistics...')
      $.ajax url: 'statistics', type: 'GET', success: (data) ->
        $("#statistics").html(data)
    )

warning = (message) ->
  r = $('<div />', class:'panel panel-warning', id='waiting')
  r.append $('<div />', class:'panel-heading', html: '<h3 class="panel-title">'+message+'</h3>')
  r.append $('<div />', class:'panel-body').append $('<img />', src: '/assets/ajax-loader.gif')
  return r

$(document).ready ->
  parent = $('#list-oxi')
  parent.html warning('loading data')
  return if !parent.length
  $.ajax 'get_list_oxi', success: (data) ->
    parent.html warning('processing data')
    table = $('<table />',class:'table')
    th = $('<thead />')
    table.append th
    row1 = $('<tr />')
    th.append row1
    row2 = $('<tr />')
    th.append row2
    tbody = $('<tbody />')
    table.append tbody
    row2.append $('<th />',html: 'Lipid')
    row2.append $('<th />', html: '#ox')
    row1.append $('<th />',colspan:2)
    n_group = 0
    groups = {}
    samples = []
    $.each data.groups, (key,group) ->
      groups[group.id] = group.name
    console.log(groups)
    last_group = null
    $.each data.samples, (key,sample) ->
      row2.append $('<th />',html: sample.short)
      samples.push sample.id
      if last_group == null
        last_group = sample.group_id
        n_group = 1
        return
      if sample.group_id != last_group
         row1.append $('<th />',colspan:n_group, html:groups[last_group])
         n_group = 0
         last_group = sample.group_id
      n_group += 1
    row1.append $('<th />',colspan:n_group, html:groups[last_group])

    $.each data, (key, oxichain) ->
      return if key=="samples"
      return if key=="groups"
      first_feature = null
      ox = 0
      $.each oxichain, (key, feature) ->
        return if key=="id"
        return if key=="lipid"
        if first_feature == null
          first_feature = feature
          return
        ox += 1
        row = $('<tr />')
        tbody.append row
        values = []
        $.each samples, (key, sample) ->
          values.push Math.round(Math.log2(feature[sample][0]/first_feature[sample][0])*1000)/1000;
        ma = Math.max.apply(Math,values);
        mi = Math.min.apply(Math,values);
        return if !isFinite(mi) || !isFinite(ma)
        $('<td />',html:'<a href="/lipids/'+oxichain.lipid.id+'">'+oxichain.lipid.common_name+'</a>',style:'overflow:hidden').appendTo row
        $('<td />',html:ox).appendTo row
        $.each values, (key, value) ->
          $('<td />',html:value,style:'background-color:'+heatmap(value,mi,ma)).appendTo row
    parent.html $('<button>',class:'btn btn-default',html:'Export as csv',click: (event) ->
      titlerow = ['lipid','class1','class2','class3','score','frag_score','mass_error','iss','adducts','oxidations']
      $.each data.samples, (key,sample) ->
        titlerow.push sample.short+' ('+groups[sample.group_id]+') [raw]'
      $.each data.samples, (key,sample) ->
        titlerow.push sample.short+' ('+groups[sample.group_id]+') [norm]'
      csv = '"'+titlerow.join('","')+'"\n'
      $.each data, (key, oxichain) ->
        return if key=="samples"
        return if key=="groups"
        first_feature = null
        ox = 0
        $.each oxichain, (key, feature) ->
          return if key=="id"
          return if key=="lipid"
          if first_feature == null
            first_feature = feature
            return
          ox += 1
          row = [oxichain.lipid.common_name, oxichain.lipid.category_, oxichain.lipid.main_class, oxichain.lipid.sub_class,oxichain.id.score, oxichain.id.fragmentation_score, oxichain.id.mass_error, oxichain.id.isotope_similarity, oxichain.id.adducts,ox]
          row = $.map row, (item) ->
            return '"'+item+'"'
          $.each samples, (key, sample) ->
            v = Math.log2(feature[sample][0]/first_feature[sample][0])
            if !isFinite(v)
              v = 'NA'
            row.push v
          $.each samples, (key, sample) ->
            v = Math.log2(feature[sample][1]/first_feature[sample][1])
            if !isFinite(v)
              v = 'NA'
            row.push v
          csv += row.join(",")+"\n"
      window.open(encodeURI('data:application/csv;charset=utf-8;filename=results.csv,'+csv))
    )
    parent.append table




