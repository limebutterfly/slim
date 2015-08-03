# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


$(document).ready ->
  $(".group").sortable connectWith: '.group', cancel: '.active'
  $(".group").disableSelection()
  $(".active").click (e) ->
    $(e.target).html prompt("Rename group",$(e.target).html())
  new_group_id = 1
  $('#actions-container').append $('<button>',text: 'add new group', class: 'btn btn-default').click (e) ->
    g_n = prompt('Enter name for new group')
    title =  $('<li>',html:g_n,class:'list-group-item active group-title')
    title.click (e) ->
      $(e.target).html prompt("Rename group",$(e.target).html())
    ng = $('<ul>',class:'list-group group',id:'group_new-'+new_group_id).append title
    $('#groups-container').append(ng)
    new_group_id += 1
    ng.sortable connectWith: '.group', cancel: '.active'
    ng.disableSelection()
  $('#actions-container').append $('<button>', text:'save grouping', class:'btn btn-default').click (e) ->
    json = []
    $.each $('#groups-container').children(), (index,group) ->
      return unless group?
      group_name = null
      group_items = []
      group_id = group.id.substr(6)
      $.each $(group).children(), (index,group_item) ->
        unless group_name?
          group_name = $(group_item).html()
          return
        group_items.push parseInt(group_item.id.substr(7))
      json.push {name: group_name, items: group_items, id: group_id}
    $.ajax url: '/samples/group_save', type: 'POST',\
           data: JSON.stringify(json),\
           contentType: 'application/json; charset=utf-8',\
           dataType: 'json',
           async: false,
           success: (e) ->
             alert('data saved!')
           error: (e) ->
             alert('error while saving grouping, please try again.')