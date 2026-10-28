/// Texto con número y palabra en singular o plural: "1 ronda", "2 rondas", "0 días".
String plural(int count, String singular, String pluralForm) =>
    '$count ${count == 1 ? singular : pluralForm}';
