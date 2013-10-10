
function playback(opts) {
  var records = [];
  var seen = {};

  function record(key, data) {
    if (seen[key]) return;
    records.push({key: key, data: data});
    seen[key] = true;
  }

  function playback() {
    var lines = [
        'library angular.core.service.playback_data;',
        '',
        'import "dart:json" as json;',
        '',
        '// Auto-generated by record-playback',
        '',
        'Map<String, String> playbackData = {'
    ];

    records.forEach(function(r) {
      var keyString = JSON.stringify(r.key).replace(/\$/g, '\\$');
      var valueString = JSON.stringify(r.data).replace(/\$/g, '\\$');
      lines.push('  ' + keyString + ': json.parse(' + valueString + '),');
    });

    lines.push('};');

    return lines.join('\n');
  }

  return {
    record: record,
    playback: playback
  }
}

module.exports = {
  playback: playback
};
