WITH sales_agg AS (
    SELECT
        cc.cc_mkt_class,
        td.t_hour,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer bc ON cs.cs_bill_customer_sk = bc.c_customer_sk
    JOIN customer sc ON cs.cs_ship_customer_sk = sc.c_customer_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = bc.c_customer_sk
    WHERE cc.cc_mkt_class LIKE '%Silly%'
      AND td.t_hour BETWEEN 9 AND 17
      AND bc.c_preferred_cust_flag = 'Y'
    GROUP BY cc.cc_mkt_class, td.t_hour
    HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
)
SELECT
    cc_mkt_class,
    t_hour,
    num_orders,
    total_net_paid,
    total_profit,
    avg_discount,
    distinct_web_pages,
    RANK() OVER (PARTITION BY cc_mkt_class ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
