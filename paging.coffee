#组合加续
group_title_continue = (group_name, word, title_name) ->
  title_name = '.change_level' unless title_name?
  $(group_name).find(title_name).each (index, value) ->
    if index isnt 0
      last_title = $($(group_name).find(title_name).get(index-1)).text()
      #判断是否上一个标题已有续，如果已有续，去除续后再进行比对，已保证同样标题出现多次都能正常加续
      num = last_title.indexOf(word)
      last_title = last_title.substr(0,num) if num > 0
      $(@).text($(@).text()+word) if $(@).text() is last_title

#标题容器中需要添加其他标题内容
title_group_add_title = (page, attr_name, replace_dom, clone_level) ->
  $(page).each (index, value) ->
    #找到页面需要复制的大标题
    title = $(@).find(".#{attr_name}").last().clone()
    if not $(@).next().find("[level=#{clone_level}]").first().hasClass(attr_name)
      since_title = $(@).next().find("[level=#{clone_level}]").first().contents()
      $(title).find(replace_dom).replaceWith(since_title)
      $(@).next().find("[level=#{clone_level}]").first().replaceWith(title)

#复制header或footer
clone_header_footer = (page, part, dom_arr) ->
  dom_arr = ['.clone'] unless dom_arr?
  header_arr = []
  $(page).find(part).each (index) ->
    if index is 0
      header_arr.push $(@).find(dom).clone() for dom in dom_arr
    else
      $(@).append(add_dom.clone()) for add_dom in header_arr

#处理总检要求每页最后一条实线和除第一条标题下的实线
summary_special = (page, dom_class) ->
  $(page).each (index,value) -> $(@).find(dom_class).last().replaceWith($(@).find(dom_class).first().clone())
   
#计数器，用于物理检验判断是同页左右布局、不同页
count_num = do ->
  count=1
  close_bag = () -> count++
  close_bag

#clone节点并处理多余节点
clone_dom = (clone_page, parallel_layout_dom, count) ->
  new_page = clone_page.get(0).cloneNode()
  if not parallel_layout_dom? or count % 2 is 0
    $(clone_page).contents().each (index, value) -> $(new_page).append($(@).get(0).cloneNode())
  $(new_page).find('.container').append($(parallel_layout_dom).first().get(0).cloneNode()) if count % 2 is 0
  new_page

#clone level节点
clone_level = (level, row) ->
  row = $(row).prev()
  row = $(row).prev() while row.length and $(row).attr('level') isnt level.toString()
  row = row.clone() if $(row).attr('level') is level.toString()
  row

#clone标题
clone_title = (max_level, newpage_custom_method, index, row, rows, next_page, content_dom, parallel_layout_dom, count, page) ->
  level_array = []
  #如果是左右布局分页置换需要添加的容器
  content_dom=parallel_layout_dom if parallel_layout_dom?
  #遍历出所有可能clone的元素，level1，level2，level3...,max_level-1考虑到同级别的上一个节点返回客户没有实际意义，所以暂时屏蔽此数据
  level_array.push(clone_level(idx, row)) for idx in [0..max_level-1] if newpage_custom_method?
  #执行用户自定义方法返回需要复制到新页面的节点
  clone_array = newpage_custom_method(level_array, row)
  #添加剩余内容,区分是否是左右分页
  if parallel_layout_dom? && count % 2 isnt 0
    $(next_page).append(dom) for dom in clone_array
    $(next_page).append(rows[index..])
    return page
  else
    $(next_page).find(content_dom).append(dom) for dom in clone_array
    $(next_page).find(content_dom).append(rows[index..])
    return next_page

#分页过程
process = (page, newpage_custom_method, parallel_layout_dom) ->
  #判断是否是左右布局
  if parallel_layout_dom?
    rows = $(page).find(parallel_layout_dom).last().contents()
  else
    rows = $(page).find('.container').contents()
  #如果存在自定义方法，遍历rows获得最大级别的值
  if newpage_custom_method?
    for row, index in rows
      max_level = if parseInt($(row).attr('level')) > parseInt($(row).prev().attr('level')) then $(row).attr('level') else $(row).prev().attr('level')
  #或得页面内容总高度
  height = parseFloat($(page).find('.container').css('height'))
  for row, index in rows
    continue unless $(row).position().top + $(row).outerHeight(true) > height
    #是否有需要每页最后一项不显示的需分到下一页显示
    if parseInt($(row).prev().attr('level')) < parseInt($(row).attr('level'))
      row = $(row).prev()
      index--
    #如果有左右分页调用计数器方法
    count = count_num() if parallel_layout_dom
    #区分左右分页与上下分页的克隆page
    if parallel_layout_dom? && count % 2 isnt 0
      $(parallel_layout_dom).after(next_page = clone_dom $(parallel_layout_dom), parallel_layout_dom, count)
    else
      $(page).after(next_page = clone_dom $(page), parallel_layout_dom, count)
    #克隆需要的需要的组标题
    next_page = clone_title(max_level, newpage_custom_method, index, row, rows, next_page, '.container', parallel_layout_dom, count, page)
    process(next_page, newpage_custom_method, parallel_layout_dom)
