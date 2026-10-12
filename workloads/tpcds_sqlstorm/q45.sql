WITH sales_agg AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_item_sk,
    ss.ss_sold_date_sk,
    SUM(ss.ss_net_paid) AS sum_net_paid,
    SUM(ss.ss_quantity) AS sum_quantity,
    SUM(ss.ss_net_profit) AS sum_net_profit
  FROM store_sales ss
  GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_sold_date_sk
),
returns_agg AS (
  SELECT
    sr.sr_store_sk,
    sr.sr_item_sk,
    sr.sr_returned_date_sk,
    SUM(sr.sr_return_amt) AS sum_return_amt,
    SUM(sr.sr_return_quantity) AS sum_return_quantity,
    SUM(sr.sr_net_loss) AS sum_net_loss
  FROM store_returns sr
  GROUP BY sr.sr_store_sk, sr.sr_item_sk, sr.sr_returned_date_sk
)
SELECT *
FROM (
  SELECT
    agg.s_state,
    agg.i_category,
    agg.d_year,
    agg.total_net_paid,
    agg.total_net_profit,
    agg.total_return_amt,
    agg.total_return_loss,
    agg.net_quantity,
    RANK() OVER (PARTITION BY agg.s_state ORDER BY agg.total_net_profit DESC) AS state_rank
  FROM (
    SELECT
      s.s_state,
      i.i_category,
      d.d_year,
      SUM(sa.sum_net_paid) AS total_net_paid,
      SUM(sa.sum_net_profit) AS total_net_profit,
      COALESCE(SUM(ra.sum_return_amt), 0) AS total_return_amt,
      COALESCE(SUM(ra.sum_net_loss), 0) AS total_return_loss,
      SUM(sa.sum_quantity) - COALESCE(SUM(ra.sum_return_quantity), 0) AS net_quantity
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
      ON sa.ss_store_sk = ra.sr_store_sk
      AND sa.ss_item_sk = ra.sr_item_sk
      AND sa.ss_sold_date_sk = ra.sr_returned_date_sk
    JOIN store s ON sa.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON sa.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 1999
    GROUP BY s.s_state, i.i_category, d.d_year
  ) agg
) ranked
WHERE ranked.state_rank <= 5
ORDER BY ranked.s_state, ranked.total_net_profit DESC
LIMIT 100
