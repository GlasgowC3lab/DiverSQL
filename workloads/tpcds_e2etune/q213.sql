WITH cs_agg AS (
    SELECT
        i.i_category,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_paid) AS cs_total_net_paid,
        SUM(cs.cs_net_profit) AS cs_total_net_profit,
        SUM(cs.cs_quantity) AS cs_total_quantity,
        AVG(cs.cs_ext_discount_amt) AS cs_avg_discount
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2452275
    GROUP BY i.i_category, hd.hd_income_band_sk
),
ws_agg AS (
    SELECT
        i.i_category,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_paid) AS ws_total_net_paid,
        SUM(ws.ws_net_profit) AS ws_total_net_profit,
        SUM(ws.ws_quantity) AS ws_total_quantity,
        AVG(ws.ws_ext_discount_amt) AS ws_avg_discount
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451910 AND 2452275
    GROUP BY i.i_category, hd.hd_income_band_sk
)
SELECT
    COALESCE(cs.i_category, ws.i_category) AS category,
    COALESCE(cs.hd_income_band_sk, ws.hd_income_band_sk) AS income_band,
    cs.cs_total_net_paid,
    ws.ws_total_net_paid,
    cs.cs_total_net_profit,
    ws.ws_total_net_profit,
    cs.cs_total_quantity,
    ws.ws_total_quantity,
    cs.cs_avg_discount,
    ws.ws_avg_discount,
    CASE WHEN cs.cs_total_net_paid > 0 THEN cs.cs_total_net_profit / cs.cs_total_net_paid END AS cs_profit_margin,
    CASE WHEN ws.ws_total_net_paid > 0 THEN ws.ws_total_net_profit / ws.ws_total_net_paid END AS ws_profit_margin
FROM cs_agg cs
FULL OUTER JOIN ws_agg ws
    ON cs.i_category = ws.i_category
    AND cs.hd_income_band_sk = ws.hd_income_band_sk
WHERE (cs.cs_total_net_paid IS NOT NULL AND cs.cs_total_net_paid > 10000)
   OR (ws.ws_total_net_paid IS NOT NULL AND ws.ws_total_net_paid > 10000)
ORDER BY cs_profit_margin DESC NULLS LAST
LIMIT 20
