WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amt
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_coupon_amt > 0
      AND cs.cs_promo_sk IN (1023, 1057)
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
store_ret_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_refunded_cash) AS total_store_refund,
        SUM(sr.sr_net_loss) AS total_store_loss,
        SUM(sr.sr_return_quantity) AS total_store_return_qty
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_refunded_cash) AS total_web_refund,
        SUM(wr.wr_net_loss) AS total_web_loss,
        SUM(wr.wr_return_quantity) AS total_web_return_qty
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
)
SELECT
    s.cs_item_sk AS item_sk,
    s.cs_sold_date_sk AS sold_date_sk,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_store_refund, 0) AS store_refund,
    COALESCE(r.total_store_loss, 0) AS store_loss,
    COALESCE(w.total_web_refund, 0) AS web_refund,
    COALESCE(w.total_web_loss, 0) AS web_loss,
    (s.total_sales - COALESCE(r.total_store_refund, 0) - COALESCE(w.total_web_refund, 0)) AS net_revenue,
    (s.total_profit - COALESCE(r.total_store_loss, 0) - COALESCE(w.total_web_loss, 0)) AS net_profit,
    RANK() OVER (ORDER BY (s.total_profit - COALESCE(r.total_store_loss, 0) - COALESCE(w.total_web_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN store_ret_agg r
    ON s.cs_item_sk = r.sr_item_sk
   AND s.cs_sold_date_sk = r.sr_returned_date_sk
LEFT JOIN web_ret_agg w
    ON s.cs_item_sk = w.wr_item_sk
   AND s.cs_sold_date_sk = w.wr_returned_date_sk
ORDER BY net_profit DESC
LIMIT 100
