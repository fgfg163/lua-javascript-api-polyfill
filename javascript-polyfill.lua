-- table api
do
  -- 复制到临时表，防止外部修改table对象导致无法运行
  local myTable = {}
  for key, value in pairs(table) do
    myTable[key] = table[key]
  end

  myTable.unpack = myTable.unpack or unpack

  myTable.length = function(tab)
    if type(tab) ~= 'table' then
      error('table.length param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    return #tab
  end

  myTable.maxn = myTable.maxn or function(tab)
    if type(tab) ~= 'table' then
      error('table.maxn param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local length = 0
    for k in pairs(tab) do
      if type(k) == 'number' and length < k and math.floor(k) == k then
        length = k
      end
    end
    return length
  end

  --[[
     返回 table 中第一个值，同时考虑字典部分和数组部分
            主要用于在字典中取出一个值
     @param {table} tab - 需要处理的table
     @return {number}, {any} - 第一个key和value
 --]]
  myTable.first = function(tab)
    if type(tab) ~= 'table' then
      error('table.first param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    if myTable.length(tab) > 0 then
      return 1, tab[1]
    end
    return next(tab)
  end

  --[[
     检查 table 是不是一个纯数组
     @param {any} tab - 可选，需要检查的table
     @return {boolean} - 是否纯数组
 --]]
  myTable.isArray = function(tab)
    if (type(tab) ~= 'table') then
      return false
    end
    local length = myTable.length(tab)
    for k, v in pairs(tab) do
      if type(k) ~= 'number' or k > length or k < 1 or math.floor(key) ~= key then
        return false
      end
    end
    return true
  end

  --[[
     分割table的数组部分，字典部分会直接去除。不会修改原table
     @param {table} tab - 需要分割的table
     @param {startIndex} tab - 可选，起始位置。默认从1开始
     @param {endIndex} tab - 可选，结束位置。默认到数组结尾
     @return {table} - 分割后的新的数组
 --]]
  myTable.slice = function(tab, startIndex, endIndex)
    if type(tab) ~= 'table' then
      error('table.slice param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local length = myTable.length(tab)
    if ((type(startIndex) == 'nil') or (startIndex < 0)) then
      startIndex = 1
    end
    if ((type(endIndex) == 'nil') or (endIndex < 0)) then
      endIndex = length
    end
    if (endIndex < 0) then
      endIndex = length + 1 + endIndex
    end

    local newTab = {}
    for i = startIndex, endIndex do
      myTable.insert(newTab, tab[i])
    end
    return newTab
  end

  --[[
     合并多个table到第一个table中，会修改第一个table的内容
     由于lua table数组的定义，合并table中的hash部分可能会变成被合并table中的数组部分
     因此这里规定number类型的正整数的key会被合并进数组部分，其余key合并进hash部分
     （hash部分可能会被覆盖）
     @param {table} tab - 被合并的table
     @param {table} ... 被合并的多个table
     @return {table} - 合并后的数组，就是参数tab
 --]]
  myTable.merge = function(tab, ...)
    if type(tab) ~= 'table' then
      error('table.merge param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end

    local args = {}
    for k = 1, select('#', ...) do
      local arg = select(k, ...)
      if type(arg) == 'table' then
        table.insert(args, arg)
      end
    end

    for k = 1, myTable.length(args) do
      local tableElement = args[k]
      for k2 = 1, myTable.maxn(tableElement) do
        if type(k2) == 'number' and math.floor(k2) == k2 and k2 >= 1 then
          myTable.insert(tab, tableElement[k2])
        end
      end
      for k2 in pairs(tableElement) do
        if type(k2) ~= 'number' or math.floor(k2) ~= k2 or k2 < 1 then
          tab[k2] = tableElement[k2]
        end
      end
    end
    return tab
  end

  --[[
     合并多个table到第一个table中，会修改第一个table的内容
     无论是否array部分，都直接合并到对应key
     @param {table} tab - 被合并的table
     @param {table} ... 被合并的多个table
     @return {table} - 合并后的数组，就是参数tab
 --]]
  myTable.assign = function(tab, ...)
    if type(tab) ~= 'table' then
      error('table.assign param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end

    local args = {}
    for k = 1, select('#', ...) do
      local arg = select(k, ...)
      if type(arg) == 'table' then
        table.insert(args, arg)
      end
    end

    for key = 1, #args do
      for key2, value in pairs(args[key]) do
        tab[key2] = value
      end
    end
    return tab
  end

  --[[
     反转table的数组部分，会生成新的table不会修改原table内容
     无论是否array部分，都直接合并到对应key
     @param {table} tab - 要反转的数组
     @return {table} - 反转后的数组
 --]]
  myTable.reverse = function(tab)
    if type(tab) ~= 'table' then
      error('table.reverse param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local result = {}
    local length = myTable.length(target)
    for key, value in pairs(tab) do
      if type(key) == 'number' and key <= length and key >= 1 and math.floor(key) == key then
        result[length + 1 - key] = value
      else
        result[key] = value
      end
    end
    return result
  end

  --[[
     过滤重复值，根据path指定的值进行过滤，数组部分会保留key较小的值，
     字典部分则会保留pairs遍历时先出现的值。
     数组和字典出现重复，则保留数组部分的key
     数组部分在删除后会重新排列，key较小的在前面
     忽略key==nil的情况
     不会修改原table
     @param {table} tab - 要过滤的table
     @param {function}/{string}/{number}/{nil} path - 过滤条件参照值
     @return {table} - 过滤后的数组
 --]]
  myTable.unique = function(tab, path)
    if type(tab) ~= 'table' then
      error('table.unique param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    if type(path) ~= 'function' and type(path) ~= 'string' and type(path) ~= 'number' and type(path) ~= 'nil' then
      error('table.unique param #2 fn expect \'function\' or \'string\' or \'number\' or \'nil\', got \'' .. type(path) .. '\'', 2)
    end
    local theMap = {}
    local tabPathList = {}
    local result = {}
    if type(path) == 'nil' then
      for key, value in pairs(tab) do
        tabPathList[key] = value
      end
    elseif type(path) == 'number' or type(path) == 'string' then
      for key, value in pairs(tab) do
        tabPathList[key] = value[path]
      end
    elseif type(path) == 'function' then
      for key, value in pairs(tab) do
        tabPathList[key] = path(value, key, tab)
      end
    end

    for key = 1, myTable.length(tabPathList) do
      local value = tabPathList[key]
      if not theMap[value] then
        theMap[value] = true
        myTable.insert(result, tab[key])
      end
    end
    local length = myTable.length(tabPathList)
    for key, value in pairs(tabPathList) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        if not theMap[value] then
          theMap[value] = true
          result[key] = tab[key]
        end
      end
    end
    return result
  end


  --[[
     过滤重复值，根据path指定的值进行过滤，数组部分会保留key较大的值，
     字典部分则会保留pairs遍历时后出现的值。
     数组和字典出现重复，则保留数组部分的key
     数组部分在删除后会重新排列，key较小的在前面
     忽略key==nil的情况
     不会修改原table
     @param {table} tab - 要过滤的table
     @param {function}/{string}/{number}/{nil} path - 过滤条件参照值
     @return {table} - 过滤后的数组
 --]]
  myTable.uniqueLast = function(tab, path)
    if type(tab) ~= 'table' then
      error('table.uniqueLast param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    if type(path) ~= 'function' and type(path) ~= 'string' and type(path) ~= 'number' and type(path) ~= 'nil' then
      error('table.uniqueLast param #2 fn expect \'function\' or \'string\' or \'number\' or \'nil\', got \'' .. type(path) .. '\'', 2)
    end
    local theMap = {}
    local tabPathList = {}
    local result = {}
    if type(path) == 'nil' then
      for key, value in pairs(tab) do
        tabPathList[key] = value
      end
    elseif type(path) == 'number' or type(path) == 'string' then
      for key, value in pairs(tab) do
        tabPathList[key] = value[path]
      end
    elseif type(path) == 'function' then
      for key, value in pairs(tab) do
        tabPathList[key] = path(value, key, tab)
      end
    end

    local length = myTable.length(tabPathList)
    for key, value in pairs(tabPathList) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        theMap[value] = key
      end
    end
    for key = 1, myTable.length(tabPathList) do
      local value = tabPathList[key]
      theMap[value] = key
    end
    for key = 1, myTable.length(tabPathList) do
      local value = tabPathList[key]
      if key == theMap[value] then
        myTable.insert(result, tab[key])
      end
    end
    for key, value in pairs(tabPathList) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        if key == theMap[value] then
          result[key] = tab[key]
        end
      end
    end
    return result
  end

  --[[
     过滤table，根据用户传入的fn返回结果删除一些值。
     数组部分在删除后会重新排列。
     不会修改原table
     @param {table} tab - 要过滤的table
     @param {function} fn - 过滤条件function
     @return {table} - 过滤后的数组
 --]]
  myTable.filter = function(tab, fn)
    if type(tab) ~= 'table' then
      error('table.filter param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    if type(fn) ~= 'function' then
      error('table.filter param #2 fn expect \'function\', got \'' .. type(fn) .. '\'', 2)
    end
    local result = {}
    for key = 1, myTable.length(tab) do
      local value = tab[key]
      if (fn(value, key, tab)) then
        myTable.insert(result, value)
      end
    end
    local length = myTable.length(tab)
    for key, value in pairs(tab) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        if fn(value, key, tab) then
          result[key] = value
        end
      end
    end
    return result
  end

  --[[
     遍历table，每个元素经过fn处理后组成新的table
     不会修改原table
     @param {table} tab - 要过滤的table
     @param {function} fn - 过滤条件function
     @return {table} - 新的table
 --]]
  myTable.map = function(tab, fn)
    if type(tab) ~= 'table' then
      error('table.map param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    if type(fn) ~= 'function' then
      error('table.map param #2 fn expect \'function\', got \'' .. type(fn) .. '\'', 2)
    end
    local result = {}
    local length = myTable.length(tab)
    for key, value in pairs(tab) do
      result[key] = fn(value, key, tab)
    end
    return result
  end

  --[[
     遍历table，返回key的列表。数组部分会按从小到大放在前面，字典部分会按pairs遍历顺序放在后面
     不会修改原table
     @param {table} tab - 要处理的table
     @return {table} - key列表
 --]]
  myTable.keys = function(tab)
    if type(tab) ~= 'table' then
      error('table.keys param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local result = {}
    for key = 1, myTable.length(tab) do
      myTable.insert(result, key)
    end
    local length = myTable.length(tab)
    for key in pairs(tab) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        myTable.insert(result, key)
      end
    end
    return result
  end

  --[[
     遍历table，返回value的列表。数组部分会按从小到大放在前面，字典部分会按pairs遍历顺序放在后面
     不会修改原table
     @param {table} tab - 要处理的table
     @return {table} - value列表
 --]]
  myTable.values = function(tab)
    if type(tab) ~= 'table' then
      error('table.values param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local result = {}
    for key = 1, myTable.length(tab) do
      myTable.insert(result, tab[key])
    end
    local length = myTable.length(tab)
    for key, value in pairs(tab) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        myTable.insert(result, tab[key])
      end
    end
    return result
  end

  --[[
     遍历table，返回{key,value}的列表。数组部分会按从小到大放在前面，字典部分会按pairs遍历顺序放在后面
     不会修改原table
     @param {table} tab - 要处理的table
     @return {table} - {key,value}列表
 --]]
  myTable.entries = function(tab)
    if type(tab) ~= 'table' then
      error('table.entries param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local result = {}
    for key = 1, myTable.length(tab) do
      myTable.insert(result, { key, tab[key] })
    end
    local length = myTable.length(tab)
    for key, value in pairs(tab) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        myTable.insert(result, { key, tab[key] })
      end
    end
    return result
  end

  --[[
     遍历table，返回key的列表。数组部分会按从小到大放在前面，
     字典部分先将number类型按从小到大放在数组之后，string类型按string的字典顺序放在之后，其他类型按pairs遍历顺序放在最后
     不会修改原table
     @param {table} tab - 要处理的table
     @return {table} - key列表
  --]]
  myTable.keysSort = function(tab)
    if type(tab) ~= 'table' then
      error('table.keysSort param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local result = {}
    for key = 1, myTable.length(tab) do
      myTable.insert(result, key)
    end
    local numberList = {}
    local stringList = {}
    local otherList = {}
    local length = myTable.length(tab)
    for key in pairs(tab) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        if type(key) == 'number' then
          myTable.insert(numberList, key)
        elseif type(key) == 'string' then
          myTable.insert(stringList, key)
        else
          myTable.insert(otherList, key)
        end
      end
    end
    table.sort(numberList)
    table.sort(stringList)
    for key = 1, myTable.length(numberList) do
      table.insert(result, numberList[key])
    end
    for key = 1, myTable.length(stringList) do
      table.insert(result, stringList[key])
    end
    for key = 1, myTable.length(otherList) do
      table.insert(result, otherList[key])
    end
    return result
  end

  --[[
    遍历table，返回value的列表。数组部分会按key从小到大放在前面，
    字典部分先将number类型key按从小到大放在数组之后，string类型key按string的字典顺序放在之后，其他类型key按pairs遍历顺序放在最后
    不会修改原table
    @param {table} tab - 要处理的table
    @return {table} - value列表
  --]]
  myTable.valuesSort = function(tab)
    if type(tab) ~= 'table' then
      error('table.valuesSort param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local result = {}
    for key = 1, myTable.length(tab) do
      myTable.insert(result, tab[key])
    end
    local numberList = {}
    local stringList = {}
    local otherList = {}
    local length = myTable.length(tab)
    for key in pairs(tab) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        if type(key) == 'number' then
          myTable.insert(numberList, key)
        elseif type(key) == 'string' then
          myTable.insert(stringList, key)
        else
          myTable.insert(otherList, key)
        end
      end
    end
    table.sort(numberList)
    table.sort(stringList)
    for key = 1, myTable.length(numberList) do
      table.insert(result, tab[numberList[key]])
    end
    for key = 1, myTable.length(stringList) do
      table.insert(result, tab[stringList[key]])
    end
    for key = 1, myTable.length(otherList) do
      table.insert(result, tab[otherList[key]])
    end
    return result
  end

  --[[
    遍历table，返回{key, value}的列表。数组部分会按key从小到大放在前面，
    字典部分先将number类型key按从小到大放在数组之后，string类型key按string的字典顺序放在之后，其他类型key按pairs遍历顺序放在最后
    不会修改原table
    @param {table} tab - 要处理的table
    @return {table} - {key, value}列表
  --]]
  myTable.entriesSort = function(tab)
    if type(tab) ~= 'table' then
      error('table.entriesSort param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local result = {}
    for key = 1, myTable.length(tab) do
      myTable.insert(result, { key, tab[key] })
    end
    local numberList = {}
    local stringList = {}
    local otherList = {}
    local length = myTable.length(tab)
    for key in pairs(tab) do
      if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
        if type(key) == 'number' then
          myTable.insert(numberList, key)
        elseif type(key) == 'string' then
          myTable.insert(stringList, key)
        else
          myTable.insert(otherList, key)
        end
      end
    end
    table.sort(numberList)
    table.sort(stringList)
    for key = 1, myTable.length(numberList) do
      table.insert(result, { numberList[key], tab[numberList[key]] })
    end
    for key = 1, myTable.length(stringList) do
      table.insert(result, { stringList[key], tab[stringList[key]] })
    end
    for key = 1, myTable.length(otherList) do
      table.insert(result, { otherList[key], tab[otherList[key]] })
    end
    return result
  end

  --[[
    遍历table寻找目标的下标。先按从小到大顺序遍历数组部分，再按pairs遍历顺序遍历字典部分
    如果没找到则返回 nil
    不考虑key==nil的情况
    @param {table} tab - 要处理的table
    @param {function}/{string}/{number}/{table} fn - 处理函数/对比值
    @return {string}/{number}/{table}, {any} - table下标,目标值
  --]]
  myTable.find = function(tab, fn)
    if type(tab) ~= 'table' then
      error('table.find param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    if type(fn) == 'nil' then
      error('table.find param #2 tab expect \'table\' or \'boolean\' or \'number\' or \'string\' or \'function\', got \'' .. type(tab) .. '\'', 2)
    end

    if type(fn) == 'function' then
      for key = 1, myTable.length(tab) do
        local res = fn(tab[key], key, tab)
        if res then
          return key, tab[key]
        end
      end
      local length = myTable.length(tab)
      for key, value in pairs(tab) do
        if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
          local res = fn(tab[key], key, tab)
          if res then
            return key, tab[key]
          end
        end
      end
    else
      for key = 1, myTable.length(tab) do
        if tab[key] == fn then
          return key, tab[key]
        end
      end
      local length = myTable.length(tab)
      for key, value in pairs(tab) do
        if type(key) ~= 'number' or key > length or key < 1 or math.floor(key) ~= key then
          if tab[key] == fn then
            return key, tab[key]
          end
        end
      end
    end
    return nil, nil
  end

  --[[
    排序。先按从小到大顺序排序数字部分，
    再按string字典顺序排序字符串部分，最后按pairs排序剩余部分
    不考虑key==nil的情况
    @param {table} tab - 要处理的table
    @return {table} - 排序结果
  --]]
  myTable.sortNumAndStr = function(tab)
    if type(tab) ~= 'table' then
      error('table.sortNumAndStr param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end
    local result = {}
    local numberList = {}
    local stringList = {}
    local otherList = {}
    local length = myTable.length(tab)
    for _, value in pairs(tab) do
      if type(value) == 'number' then
        table.insert(numberList, value)
      elseif type(value) == 'string' then
        table.insert(stringList, value)
      else
        table.insert(otherList, value)
      end
    end
    table.sort(numberList)
    table.sort(stringList)
    for key = 1, myTable.length(numberList) do
      table.insert(result, tab[numberList[key]])
    end
    for key = 1, myTable.length(stringList) do
      table.insert(result, tab[stringList[key]])
    end
    for key = 1, myTable.length(otherList) do
      table.insert(result, tab[otherList[key]])
    end
    return result
  end

  --[[
    table数组部分的交集。字典部分会过滤掉
    不会改变原有table
    @param {table} tab - 要处理的table
    @param {table} ... - 要相交的table
    @return {table} - 交集table
  --]]
  myTable.intersect = function(tab, ...)
    if type(tab) ~= 'table' then
      error('table.intersect param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end

    local args = {}
    for k = 1, select('#', ...) do
      local arg = select(k, ...)
      if type(arg) == 'table' then
        table.insert(args, arg)
      end
    end

    local result = {}
    for key = 1, #tab do
      result[key] = tab[key]
    end
    for _, v in ipairs(args) do
      local newRes = {}
      local theSet = {}
      for _, v2 in ipairs(v) do
        theSet[v2] = v2
      end
      for _, v2 in ipairs(result) do
        if type(theSet[v2]) ~= 'nil' then
          table.insert(newRes, v2)
        end
      end
      result = newRes
    end
    return tab
  end

  --[[
    table数组部分的差集。字典部分会过滤掉
    不会改变原有table
    @param {table} tab - 要处理的table
    @param {table} ... - 要相差的table
    @return {table} - 差集table
  --]]
  myTable.subtract = function(tab, ...)
    if type(tab) ~= 'table' then
      error('table.intersect param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end

    local args = {}
    for k = 1, select('#', ...) do
      local arg = select(k, ...)
      if type(arg) == 'table' then
        table.insert(args, arg)
      end
    end

    local result = {}
    for key = 1, #tab do
      result[key] = tab[key]
    end
    for _, v in ipairs(args) do
      local newRes = {}
      local theSet = {}
      for _, v2 in ipairs(v) do
        theSet[v2] = v2
      end
      for _, v2 in ipairs(result) do
        if type(theSet[v2]) == 'nil' then
          table.insert(newRes, v2)
        end
      end
      result = newRes
    end
    return tab
  end

  --[[
    table数组部分的并集。字典部分会过滤掉
    不会改变原有table
    @param {table} ... - 要相并的table
    @return {table} - 并集table
  --]]
  myTable.union = function(...)
    local args = {}
    for k = 1, select('#', ...) do
      local arg = select(k, ...)
      if type(arg) == 'table' then
        table.insert(args, arg)
      end
    end

    if type(args[1]) ~= 'table' then
      error('table.intersect param #1 tab expect \'table\', got \'' .. type(tab) .. '\'', 2)
    end

    local result = {}
    local resultMap = {}
    for _, v in ipairs(args) do
      for _, v2 in ipairs(v) do
        if not resultMap[v2] then
          resultMap[v2] = true
          table.insert(result, v2)
        end
      end
    end
    return result
  end

  -- 赋值到 table 对象上
  for key, value in pairs(myTable) do
    table[key] = table[key] or myTable[key]
  end
end

-- string api
do
  local myString = {}
  for key, value in pairs(string) do
    myString[key] = string[key]
  end

  --[[
     字符串分割
     @param {string} str - 需要分割的字符串
     @param {string} d - 分割参照物
     @return {table} - 分割后的字符串列表
  --]]
  myString.split = function(str, d)
    if str == '' and d ~= '' then
      return { str }
    elseif str ~= '' and d == '' then
      local lst = {}
      for key = 1, myString.len(str) do
        table.insert(lst, myString.sub(str, key, 1))
      end
      return lst
    else
      local lst = {}
      local n = myString.len(str) --长度
      local start = 1
      while start <= n do
        local i = myString.find(str, d, start) -- find 'next' 0
        if i == nil then
          table.insert(lst, myString.sub(str, start, n))
          break
        end
        table.insert(lst, myString.sub(str, start, i - 1))
        if i == n then
          table.insert(lst, '')
          break
        end
        start = i + 1
      end
      return lst
    end
  end

  --[[
     字符串头部匹配
     @param {string} str - 需要对比的字符串
     @param {string} pattern - 对比内容
     @return {table} - 分割后的字符串列表
  --]]
  myString.startWith = function(str, pattern)
    if type(str) ~= 'string' then
      return false
    end
    if type(pattern) ~= 'string' then
      return false
    end
    if myString.sub(str, 1, myString.len(pattern)) == pattern then
      return true
    end
    return false
  end

  --[[
     字符尾部匹配
     @param {string} str - 需要对比的字符串
     @param {string} pattern - 对比内容
     @return {table} - 分割后的字符串列表
  --]]
  myString.endWith = function(str, pattern)
    if type(str) ~= 'string' then
      return false
    end
    if type(pattern) ~= 'string' then
      return false
    end
    if myString.sub(str, 1, (0 - myString.len(pattern))) == pattern then
      return true
    end
    return false
  end

  for key, value in pairs(myString) do
    string[key] = string[key] or myString[key]
  end
end

-- math api
do
  local myMath = {}
  for key, value in pairs(math) do
    myMath[key] = value
  end

  myMath.isNan = function(num)
    if (num ~= num) then
      return true
    end
    return false
  end

  myMath.isInf = function(num)
    if (num == myMath.huge) then
      return true
    end
    return false
  end

  myMath.trueNumber = function(num)
    if (type(num) ~= 'number') then
      return nil
    end
    if (myMath.isNan(num)) then
      return nil
    end
    if (myMath.isInf(num)) then
      return nil
    end
    return num
  end

  myMath.maxTable = function(tab, path)
    local maxNum
    local maxTab
    local maxKey
    if not path then
      return myMath.max(table.unpack(tab))
    elseif type(path) == 'string' or type(path) == 'number' then
      for key, item in pairs(tab) do
        if not maxNum or maxNum < item[path] then
          maxNum = item[path]
          maxTab = item
          maxKey = key
        end
      end
    elseif type(path) == 'function' then
      for key, item in pairs(tab) do
        local theNum = path(item, key, tab)
        if not maxNum or maxNum < theNum then
          maxNum = theNum
          maxTab = item
          maxKey = key
        end
      end
    end
    return maxTab, maxKey
  end

  myMath.minTable = function(tab, path)
    local maxNum
    local minTab
    local minKey
    if not path then
      return myMath.max(table.unpack(tab))
    elseif type(path) == 'string' or type(path) == 'number' then
      for key, item in pairs(tab) do
        if not maxNum or maxNum > item[path] then
          maxNum = item[path]
          minTab = item
          minKey = key
        end
      end
    elseif type(path) == 'function' then
      for key, item in pairs(tab) do
        local theNum = path(item, key, tab)
        if not maxNum or maxNum > theNum then
          maxNum = theNum
          minTab = item
          minKey = key
        end
      end
    end
    return minTab, minKey
  end


  myMath.mod = function(m, n)
    local a1 = myMath.modf(m / n)
    return m - a1 * n
  end

  for key, value in pairs(myMath) do
    math[key] = math[key] or myMath[key]
  end
end
