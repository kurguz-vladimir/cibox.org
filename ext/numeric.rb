
class Numeric

  K = 2.0**10
  M = 2.0**20
  G = 2.0**30
  T = 2.0**40
  P = 2.0**50
  E = 2.0**60
  Z = 2.0**70
  Y = 2.0**80

  def to_human_size opts = {}
    max_digits = opts[:max_digits] || 3
    bytes = self
    prefix = ""
    if bytes < 0
      prefix = "-"
      bytes = 0 - bytes
    end
    value, suffix, precision = case bytes
                                 when 0...K
                                   [bytes, 'B', 0]
                                 else
                                   value, suffix = case bytes
                                                     when K...M then
                                                       [bytes / K, 'KB']
                                                     when M...G then
                                                       [bytes / M, 'MB']
                                                     when G...T then
                                                       [bytes / G, 'GB']
                                                     when T...P then
                                                       [bytes / T, 'TB']
                                                     when P...E then
                                                       [bytes / P, 'PB']
                                                     when E...Z then
                                                       [bytes / E, 'EB']
                                                     when Z...Y then
                                                       [bytes / Z, 'ZB']
                                                     else
                                                       [bytes / Y, 'YB']
                                                   end
                                   used_digits = case value
                                                   when 0...10 then
                                                     1
                                                   when 10...100 then
                                                     2
                                                   when 100...1000 then
                                                     3
                                                 end
                                   leftover_digits = max_digits - used_digits.to_i
                                   [value, suffix, leftover_digits > 0 ? leftover_digits : 0]
                               end
    prefix << ("%.#{precision}f" % value) << suffix
  end

end
