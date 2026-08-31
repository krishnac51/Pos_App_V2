String buildOttuWebViewAutofillScript({
  String? email,
  String? name,
  String? phone,
}) {
  if ((email == null || email.isEmpty) &&
      (name == null || name.isEmpty) &&
      (phone == null || phone.isEmpty)) {
    return '';
  }

  final jsEmail = _escapeJs(email ?? '');
  final jsName = _escapeJs(name ?? '');
  final jsPhone = _escapeJs(phone ?? '');

  return '''
(function() {
  var email = "$jsEmail";
  var name = "$jsName";
  var phone = "$jsPhone";

  function setValue(el, value) {
    if (!el || !value || (el.value && el.value.trim() !== "")) return;
    el.value = value;
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
  }

  function fillBySelectors(selectors, value) {
    selectors.forEach(function(selector) {
      document.querySelectorAll(selector).forEach(function(el) {
        setValue(el, value);
      });
    });
  }

  if (email) {
    fillBySelectors([
      'input[type="email"]',
      'input[name*="email" i]',
      'input[id*="email" i]',
      'input[autocomplete="email"]'
    ], email);
  }

  if (name) {
    fillBySelectors([
      'input[name*="first" i][name*="name" i]',
      'input[name="first_name"]',
      'input[id*="first" i][id*="name" i]',
      'input[name*="name" i]:not([name*="last" i])',
      'input[autocomplete="given-name"]'
    ], name);
  }

  if (phone) {
    fillBySelectors([
      'input[type="tel"]',
      'input[name*="phone" i]',
      'input[id*="phone" i]',
      'input[autocomplete="tel"]'
    ], phone);
  }
})();
''';
}

String _escapeJs(String value) {
  return value
      .replaceAll('\\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', '');
}
