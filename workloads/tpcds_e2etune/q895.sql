WITH store_agg AS (
    SELECT
        i.i_category,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_current_price > 100
      AND ss.ss_sold_date_sk BETWEEN 2450800 AND 2451200
    GROUP BY i.i_category, hd.hd_income_band_sk
),
web_agg AS (
    SELECT
        i.i_category,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS total_web_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_current_price > 100
      AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2451200
    GROUP BY i.i_category, hd.hd_income_band_sk
),
returns_agg AS (
    SELECT
        i.i_category,
        hd.hd_income_band_sk,
        SUM(wr.wr_net_loss) AS total_returns_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Defective'
      AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2451200
    GROUP BY i.i_category, hd.hd_income_band_sk
)
SELECT
    COALESCE(sa.i_category, wa.i_category, ra.i_category) AS i_category,
    COALESCE(sa.hd_income_band_sk, wa.hd_income_band_sk, ra.hd_income_band_sk) AS hd_income_band_sk,
    COALESCE(sa.total_store_profit, 0) AS total_store_profit,
    COALESCE(wa.total_web_profit, 0) AS total_web_profit,
    COALESCE(ra.total_returns_loss, 0) AS total_returns_loss,
    (COALESCE(sa.total_store_profit, 0) + COALESCE(wa.total_web_profit, 0) - COALESCE(ra.total_returns_loss, 0)) AS net_profit_after_returns,
    COALESCE(sa.avg_store_discount, 0) AS avg_store_discount,
    COALESCE(wa.avg_web_discount, 0) AS avg_web_discount,
    COALESCE(sa.distinct_store_customers, 0) AS distinct_store_customers,
    COALESCE(wa.distinct_web_customers, 0) AS distinct_web_customers,
    RANK() OVER (
        PARTITION BY COALESCE(sa.hd_income_band_sk, wa.hd_income_band_sk, ra.hd_income_band_sk)
        ORDER BY (COALESCE(sa.total_store_profit, 0) + COALESCE(wa.total_web_profit, 0) - COALESCE(ra.total_returns_loss, 0)) DESC
    ) AS profit_rank
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.i_category = wa.i_category
   AND sa.hd_income_band_sk = wa.hd_income_band_sk
FULL OUTER JOIN returns_agg ra
    ON COALESCE(sa.i_category, wa.i_category) = ra.i_category
   AND COALESCE(sa.hd_income_band_sk, wa.hd_income_band_sk) = ra.hd_income_band_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
