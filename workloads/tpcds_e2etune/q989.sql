WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2451920
      AND cs.cs_net_paid_inc_ship > 500
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
returns_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS returns_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2451910 AND 2451920
      AND sr.sr_return_amt > 100
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
)
SELECT
    s.cs_item_sk,
    s.cs_sold_date_sk,
    s.total_quantity,
    s.total_net_profit,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_adj,
    ROUND((s.total_net_profit - COALESCE(r.total_net_loss, 0)) / s.total_quantity, 2) AS profit_per_unit,
    RANK() OVER (ORDER BY (s.total_net_profit - COALESCE(r.total_net_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cs_item_sk = r.sr_item_sk
   AND s.cs_sold_date_sk = r.sr_returned_date_sk
WHERE s.total_quantity > 0
ORDER BY net_profit_adj DESC
LIMIT 100
