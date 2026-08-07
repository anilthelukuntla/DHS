// Call the dataTables jQuery plugin
$(document).ready(function() {
  $('#dataTable').DataTable({"searching":false,
  "bLengthChange": false,
  "bFilter": true,
  "bInfo": true,
  "bAutoWidth": false });
});
