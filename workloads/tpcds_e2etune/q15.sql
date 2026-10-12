WITH store_customer_returns AS (
  SELECT
    s.s_store_sk,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    c.c_current_hdemo_sk,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
  FROM store_returns sr
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450500 AND 2451500
    AND c.c_birth_country = 'IRELAND'
    AND s.s_state IN ('CA', 'NY', 'TX')
  GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, s.s_state, c.c_current_hdemo_sk
)
SELECT
  scr.s_store_id,
  scr.s_store_name,
  scr.s_state,
  scr.c_current_hdemo_sk AS household_demo,
  scr.total_net_loss,
  scr.total_returns,
  scr.avg_return_qty,
  scr.distinct_customers,
  scr.total_net_loss / NULLIF(scr.distinct_customers, 0) AS net_loss_per_customer,
  RANK() OVER (PARTITION BY scr.s_state ORDER BY scr.total_net_loss DESC) AS rank_within_state
FROM store_customer_returns scr
WHERE scr.total_returns >= 15
ORDER BY scr.s_state, rank_within_state
LIMIT 25
