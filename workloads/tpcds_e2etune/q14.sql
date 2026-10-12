WITH aggregated AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        hd.hd_buy_potential,
        ws.web_name,
        COUNT(*) AS num_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_net_profit) AS avg_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND cc.cc_city = 'Greenwood'
      AND hd.hd_buy_potential = 'High'
      AND wp.wp_type = 'Product'
      AND d_wp_creation.d_year = 2002
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        hd.hd_buy_potential,
        ws.web_name
    HAVING COUNT(*) >= 50
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    hd_buy_potential,
    web_name,
    num_sales,
    total_quantity,
    total_net_profit,
    avg_net_profit,
    RANK() OVER (ORDER BY avg_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY avg_net_profit DESC
LIMIT 10
