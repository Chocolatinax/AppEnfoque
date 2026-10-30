String plural(int count, String singular, String pluralForm) =>
    '$count ${count == 1 ? singular : pluralForm}';
