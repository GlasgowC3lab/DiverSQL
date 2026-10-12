WITH catalog_sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cs.cs_call_center_sk, cs.cs_item_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cr.cr_call_center_sk, cr.cr_item_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_mkt_class,
    SUM(cs_agg.total_net_profit) - COALESCE(SUM(cr_agg.total_net_loss), 0) AS net_profit_after_returns,
    SUM(cs_agg.total_quantity) AS total_quantity_sold,
    COALESCE(SUM(cr_agg.total_return_quantity), 0) AS total_quantity_returned,
    AVG(cs_agg.avg_discount) AS avg_discount_amount
FROM catalog_sales_agg cs_agg
LEFT JOIN catalog_returns_agg cr_agg
    ON cs_agg.cs_call_center_sk = cr_agg.cr_call_center_sk
    AND cs_agg.cs_item_sk = cr_agg.cr_item_sk
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_class = 'large'
  AND cc.cc_gmt_offset = -5.00
  AND cc.cc_rec_start_date <= DATE '2000-12-31'
  AND (cc.cc_rec_end_date IS NULL OR cc.cc_rec_end_date >= DATE '2000-01-01')
GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_mkt_class
ORDER BY net_profit_after_returns DESC
LIMIT 10
