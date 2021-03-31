# typed: false
# frozen_string_literal: true

# Provides metric-related methods for testing
#
module TestMetrics
  def add_metric(key, value)
    @metrics[key] = [] unless @metrics[key]
    @metrics[key].append(value)
  end

  def report_metrics(clear: true)
    metrics = @metrics
    show do
      metrics.each do |k, v|
        note "#{k}: #{average_in_milliseconds(v)} ms"
      end
    end
    @metrics = {} if clear
  end

  def average_in_milliseconds(values)
    ((values.sum(0.0) / values.length) * 1000).round(2)
  end
end
