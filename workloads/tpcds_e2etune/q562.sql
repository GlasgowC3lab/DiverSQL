SELECT
    category,
    hour,
    income_band,
    COALESCE(purpose, 'No Promotion') AS promotion_purpose,
    SUM(net_loss) AS total_net_loss,
    SUM(return_quantity) AS total_return_quantity,
    COUNT(*) AS num_returns
FROM (
    SELECT i.i_category AS category,
           td.t_hour AS hour,
           hd.hd_income_band_sk AS income_band,
           p.p_purpose AS purpose,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE cr.cr_return_amount > 0
      AND td.t_hour BETWEEN 9 AND 17
    UNION ALL
    SELECT i.i_category AS category,
           td.t_hour AS hour,
           hd.hd_income_band_sk AS income_band,
           p.p_purpose AS purpose,
           wr.wr_net_loss AS net_loss,
           wr.wr_return_quantity AS return_quantity
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE wr.wr_return_quantity > 0
      AND td.t_hour BETWEEN 9 AND 17
) AS combined
GROUP BY category, hour, income_band, COALESCE(purpose, 'No Promotion')
HAVING SUM(net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 20
