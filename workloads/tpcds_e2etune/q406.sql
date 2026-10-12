WITH
store_agg AS (
    SELECT
        sr.sr_reason_sk AS reason_sk,
        c.c_current_cdemo_sk AS demo_sk,
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        COUNT(DISTINCT sr.sr_customer_sk) AS store_customer_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND sr.sr_returned_date_sk >= 2450000
    GROUP BY sr.sr_reason_sk, c.c_current_cdemo_sk, sr.sr_item_sk
),
web_agg AS (
    SELECT
        wr.wr_reason_sk AS reason_sk,
        c.c_current_cdemo_sk AS demo_sk,
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS web_customer_cnt
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND wr.wr_returned_date_sk >= 2450000
    GROUP BY wr.wr_reason_sk, c.c_current_cdemo_sk, wr.wr_item_sk
),
inventory_max AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               inv_quantity_on_hand,
               ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_quantity_on_hand DESC) AS rn
        FROM inventory
    ) t
    WHERE rn = 1
),
warehouse_info AS (
    SELECT w_warehouse_sk,
           w_city,
           w_state,
           w_country
    FROM warehouse
)
SELECT
    r.r_reason_desc,
    COALESCE(s.demo_sk, w.demo_sk) AS demographic_sk,
    COALESCE(s.item_sk, w.item_sk) AS item_sk,
    COALESCE(s.store_net_loss, 0) AS store_net_loss,
    COALESCE(w.web_net_loss, 0) AS web_net_loss,
    CASE WHEN COALESCE(s.store_net_loss, 0) = 0 THEN NULL
         ELSE COALESCE(w.web_net_loss, 0) / COALESCE(s.store_net_loss, 0) END AS web_to_store_loss_ratio,
    COALESCE(s.store_return_qty, 0) + COALESCE(w.web_return_qty, 0) AS total_return_qty,
    COALESCE(s.store_customer_cnt, 0) + COALESCE(w.web_customer_cnt, 0) AS total_customer_cnt,
    i.inv_quantity_on_hand AS inventory_qty_on_hand,
    wi.w_city,
    wi.w_state,
    wi.w_country
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.reason_sk = w.reason_sk
   AND s.demo_sk = w.demo_sk
   AND s.item_sk = w.item_sk
JOIN reason r
    ON COALESCE(s.reason_sk, w.reason_sk) = r.r_reason_sk
LEFT JOIN inventory_max i
    ON i.inv_item_sk = COALESCE(s.item_sk, w.item_sk)
LEFT JOIN warehouse_info wi
    ON i.inv_warehouse_sk = wi.w_warehouse_sk
WHERE (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) > 0
ORDER BY store_net_loss DESC
LIMIT 200
