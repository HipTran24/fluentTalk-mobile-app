-- Previous service versions manufactured scores without provider/acoustic
-- evidence. Preserve the records, but never present those scores as measured.
UPDATE session_feedbacks
SET status = 'unavailable',
    overall_band = NULL,
    summary_vi = 'Phiên đã được lưu. Đánh giá cũ chưa có bằng chứng được kiểm chứng.',
    dimensions = '[{"dimension":"fluency","estimatedBand":null,"confidence":null,"evidence":[],"scorerProvider":null,"scorerVersion":null},{"dimension":"lexical","estimatedBand":null,"confidence":null,"evidence":[],"scorerProvider":null,"scorerVersion":null},{"dimension":"grammar","estimatedBand":null,"confidence":null,"evidence":[],"scorerProvider":null,"scorerVersion":null},{"dimension":"pronunciation","estimatedBand":null,"confidence":null,"evidence":[],"scorerProvider":null,"scorerVersion":null}]';
