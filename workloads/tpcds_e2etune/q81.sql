WITH catalog AS (
  SELECT
    cr.cr_returned_date_sk AS return_date_sk,
    cr.cr_returned_time_sk AS return_time_sk,
    i.i_category AS i_category,
    i.i_brand AS i_brand,
    cd.cd_gender AS cd_gender,
    r.r_reason_desc AS r_reason_desc,
    cr.cr_return_amount AS return_amount,
    cr.cr_return_tax AS return_tax,
    cr.cr_return_quantity AS return_quantity,
    (
      SELECT COALESCE(SUM(inv.inv_quantity_on_hand), 0)
      FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = cr.cr_returned_date_sk
    ) AS on_hand_qty,
    'catalog' AS channel
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
),
web AS (
  SELECT
    wr.wr_returned_date_sk AS return_date_sk,
    wr.wr_returned_time_sk AS return_time_sk,
    i.i_category AS i_category,
    i.i_brand AS i_brand,
    cd.cd_gender AS cd_gender,
    r.r_reason_desc AS r_reason_desc,
    wr.wr_return_amt AS return_amount,
    wr.wr_return_tax AS return_tax,
    wr.wr_return_quantity AS return_quantity,
    (
      SELECT COALESCE(SUM(inv.inv_quantity_on_hand), 0)
      FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = wr.wr_returned_date_sk
    ) AS on_hand_qty,
    'web' AS channel
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
)
SELECT
  channel,
  i_category,
  cd_gender,
  r_reason_desc,
  COUNT(*) AS return_cnt,
  SUM(return_amount) AS total_return_amount,
  AVG(return_tax) AS avg_return_tax,
  SUM(return_quantity) AS total_quantity,
  SUM(on_hand_qty) AS total_on_hand_qty,
  RANK() OVER (PARTITION BY channel ORDER BY SUM(return_amount) DESC) AS amount_rank
FROM (
  SELECT * FROM catalog
  UNION ALL
  SELECT * FROM web
) t
GROUP BY channel, i_category, cd_gender, r_reason_desc
HAVING COUNT(*) > 5
ORDER BY channel, total_return_amount DESC
LIMIT 200
