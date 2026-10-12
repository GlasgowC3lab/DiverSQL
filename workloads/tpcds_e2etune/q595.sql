SELECT *
FROM (
    SELECT
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        ROUND((SUM(cs.cs_net_profit) - SUM(wr.wr_net_loss)) / NULLIF(SUM(cs.cs_net_profit), 0) * 100, 2) AS profit_after_returns_pct,
        RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND cd.cd_purchase_estimate > 5000
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
      AND wp.wp_type = 'Home'
    GROUP BY cc.cc_name, w.w_warehouse_name, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(cs.cs_net_profit) > 100000
) t
WHERE profit_rank <= 50
ORDER BY total_net_profit DESC
LIMIT 50
