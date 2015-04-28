class SearchForm
  constructor: (el)->
    @el = el

    $(el).on 'submit', (e) =>
      e.preventDefault()
      @submit()

    $("#{@el} .input-month").datepicker({
      format: 'yyyy/mm'
      viewMode: 'months'
      minViewMode: 'months'
      language: 'ja'
    })

    default_type = $("#{@el} a.economic-index-type:first")
    @current_type = default_type.text()
    @current_url = default_type.attr('href')
    $("#{@el} span.economic-index-type__label").text(@current_type)

    $("#{@el} a.economic-index-type").on "click", (e) =>
      e.preventDefault()
      @current_type = $(e.target).text()
      @current_url = $(e.target).attr('href')
      $("#{@el} span.economic-index-type__label").text(@current_type)
      @submit()

  startAt: ->
    $("#{@el} .start-at").val()

  endAt: ->
    $("#{@el} .end-at").val()

  update: (start_at, end_at) ->
    $("#{@el} .start-at").datepicker('update', start_at)
    $("#{@el} .end-at").datepicker('update', end_at)

  type: ->
    @current_type

  url: ->
    @current_url

  onSubmit: (func) ->
    @handlers = [] unless @handlers
    @handlers.push(func)

  submit: ->
    return if !@handlers
    for handler in @handlers
      handler()

class EconomyIndexChart
  constructor: (el, searchForm) ->
    @el = el
    @searchForm = searchForm
    @searchForm.onSubmit(@search)
    @ctx = $("#{@el} .economy-index-chart")[0].getContext("2d")

  reloadData: ->
    url = @searchForm.url()
    return if url == @current_url
    @current_url = url
    $.ajax
      url: @searchForm.url()
      async: false
      beforeSend: (xhr) =>
        xhr.overrideMimeType('text/plain; charset=Shift_JIS')
      success: (data) =>
        csv = $.csv.toArrays(data)
        @updateDataset(csv)
      error: (xhr, status, error) =>
        $(@el).html("data loading error: #{status}")

  updateDataset: (csv) =>
    @dataset = {}
    min = '9999/99'
    max = '0000/00'
    for row, i in csv
      continue if !row[3]
      year = parseInt(row[1])
      month = parseInt(row[2].replace(/月/, ''))
      val = parseFloat(row[3])
      continue if !year || !month || !val
      key = "#{year}/#{"0#{month}".substr(-2)}"
      @dataset[key] = val
      min = key if min > key
      max = key if max < key
    @min = min unless @min
    @max = max unless @max
    @updateSearchForm()

  updateSearchForm: ->
    start_at = @searchForm.startAt() || @min
    end_at = @searchForm.endAt() || @max
    @searchForm.update(start_at, end_at)

  drawChart: ->
    labels = []
    points = []
    for key, val of @dataset
      continue if @min && key < @min
      continue if @max && key > @max
      labels.push(key)
      points.push(val)
    options =
      responsive: true
    chartDef =
      labels: labels
      datasets: [
        {
          fillColor: "rgba(220,220,220,0.2)"
          strokeColor: "rgba(220,220,220,1)"
          pointColor: "rgba(220,220,220,1)"
          pointStrokeColor: "#fff"
          pointHighlightFill: "#fff"
          pointHighlightStroke: "rgba(220,220,220,1)"
          data: points
        }
      ]
    new Chart(@ctx).Line(chartDef, options)

  search: =>
    @min = @searchForm.startAt()
    @max = @searchForm.endAt()
    @reloadData()
    @drawChart()

$ ->
  searchForm = new SearchForm('#search')
  economyIndexChart = new EconomyIndexChart('#content', searchForm)
  searchForm.submit()
