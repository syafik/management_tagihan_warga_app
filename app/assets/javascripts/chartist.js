//Horizontal bar chart
  if ($('#ct-chart-horizontal-bar').length) {
    new Chartist.Bar('#ct-chart-horizontal-bar', {
      labels: ['Aassalam', 'Basdasd', 'Ccccc', 'Deee', 'Efff', 'Fggg', 'Gooo'],
      series: [
        [5, 4, 3, 7, 5, 10, 3]
      ]
    }, {
      seriesBarDistance: 10,
      reverseData: true,
      horizontalBars: true,
      axisY: {
        offset: 70
      }
    });
  }

  if ($('#ct-chart-horizontal-bar2').length) {
    new Chartist.Bar('#ct-chart-horizontal-bar2', {
      labels: ['Aassalam', 'Basdasd', 'Ccccc', 'Deee', 'Efff', 'Fggg', 'Gooo'],
      series: [
        [5, 4, 3, 7, 5, 10, 3]
      ]
    }, {
      seriesBarDistance: 10,
      reverseData: true,
      horizontalBars: true,
      axisY: {
        offset: 70
      }
    });
  }