@drawChart = (_name, _elevations) ->
  lineChartData = 
    labels: _elevations
    datasets: [ {
      label: _name
      fillColor: 'rgba(255,70,33,0.6)'
      strokeColor: 'rgba(220,70,33,1)'
      pointDot: false
      pointColor: 'rgba(255,70,33,1)'
      pointStrokeColor: '#fff'
      pointHighlightFill: '#fff'
      pointHighlightStroke: 'rgba(220,220,220,0)'
      data: _elevations
    } ]
  ctx = document.getElementById('chart').getContext('2d')
  window.myLine = new Chart(ctx).Line(lineChartData, {responsive: true, scaleShowGridLines: false, scaleShowLabels: false})