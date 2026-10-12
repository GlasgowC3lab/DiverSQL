WITH
  sample_store AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
  ),
  store_joined AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      sr.sr_net_loss,
      cd.cd_gender,
      cd.cd_purchase_estimate,
      i.i_item_id,
      i.i_category,
      i.i_current_price,
      d.d_week_seq,
      t.t_time,
      t.t_am_pm
    FROM sample_store sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate >= 5000
      AND t.t_time >= 12
      AND d.d_week_seq BETWEEN 10 AND 20
      AND i.i_current_price BETWEEN 20 AND 100
  ),
  web_joined AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      cd.cd_gender,
      cd.cd_purchase_estimate,
      i.i_item_id,
      i.i_category,
      i.i_current_price,
      d.d_week_seq,
      t.t_time,
      t.t_am_pm
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate >= 5000
      AND t.t_time >= 12
      AND d.d_week_seq BETWEEN 10 AND 20
      AND i.i_current_price BETWEEN 20 AND 100
  ),
  store_items_excluding_web AS (
    SELECT sr_item_sk
    FROM store_joined
    EXCEPT
    SELECT wr_item_sk
    FROM web_joined
  ),
  common_high_value_items AS (
    SELECT sr_item_sk
    FROM store_joined
    WHERE sr_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns)
    INTERSECT
    SELECT wr_item_sk
    FROM web_joined
    WHERE wr_return_amt > (SELECT AVG(wr_return_amt) FROM web_returns)
  ),
  aggregated AS (
    SELECT
      s.sr_item_sk          AS item_sk,
      s.i_item_id,
      s.i_category,
      s.cd_gender,
      COUNT(*)                         AS store_return_cnt,
      SUM(s.sr_return_amt)             AS store_return_total,
      AVG(CASE WHEN s.sr_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns) THEN 1 ELSE 0 END) AS store_high_return_ratio,
      COUNT(w.wr_item_sk)              AS web_return_cnt,
      SUM(w.wr_return_amt)             AS web_return_total,
      AVG(CASE WHEN w.wr_return_amt > (SELECT AVG(wr_return_amt) FROM web_returns) THEN 1 ELSE 0 END)   AS web_high_return_ratio,
      SUM(CASE WHEN s.sr_return_amt > w.wr_return_amt THEN s.sr_return_amt ELSE w.wr_return_amt END) AS max_return_sum
    FROM store_joined s
    LEFT JOIN web_joined w
      ON s.sr_item_sk = w.wr_item_sk
     AND s.cd_gender = w.cd_gender
    GROUP BY s.sr_item_sk, s.i_item_id, s.i_category, s.cd_gender
  )
SELECT
  item_sk,
  i_item_id,
  i_category,
  cd_gender,
  store_return_cnt,
  store_return_total,
  store_high_return_ratio,
  web_return_cnt,
  web_return_total,
  web_high_return_ratio,
  max_return_sum
FROM aggregated
WHERE item_sk IN (SELECT sr_item_sk FROM store_items_excluding_web)
  AND item_sk IN (SELECT sr_item_sk FROM common_high_value_items)
ORDER BY store_return_total DESC
LIMIT 100
