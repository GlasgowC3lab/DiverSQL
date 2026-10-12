WITH combined_sales AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           'store' AS sales_channel
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_bill_customer_sk,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit,
           'catalog' AS sales_channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           'web' AS sales_channel
    FROM web_sales ws
),
sales_with_dim AS (
    SELECT
        cs.date_sk,
        d.d_year,
        date_format(d.d_date, 'yyyy-MM') AS year_month,
        cs.item_sk,
        i.i_category,
        cs.customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cs.quantity,
        cs.net_paid,
        cs.net_profit,
        cs.sales_channel
    FROM combined_sales cs
    JOIN date_dim d ON cs.date_sk = d.d_date_sk
    JOIN item i ON cs.item_sk = i.i_item_sk
    JOIN customer c ON cs.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
category_monthly_agg AS (
    SELECT
        year_month,
        i_category,
        sales_channel,
        SUM(net_profit) AS total_profit,
        SUM(net_paid) AS total_sales,
        SUM(quantity) AS total_quantity
    FROM sales_with_dim
    GROUP BY year_month, i_category, sales_channel
),
category_monthly AS (
    SELECT
        cm.*,
        ROW_NUMBER() OVER (PARTITION BY year_month ORDER BY total_profit DESC) AS rank_by_profit
    FROM category_monthly_agg cm
),
category_trend AS (
    SELECT
        cm.year_month,
        cm.i_category,
        cm.sales_channel,
        cm.total_profit,
        LAG(cm.total_profit) OVER (PARTITION BY cm.i_category, cm.sales_channel ORDER BY cm.year_month) AS prev_month_profit,
        CASE
            WHEN LAG(cm.total_profit) OVER (PARTITION BY cm.i_category, cm.sales_channel ORDER BY cm.year_month) = 0 THEN NULL
            ELSE ((cm.total_profit - LAG(cm.total_profit) OVER (PARTITION BY cm.i_category, cm.sales_channel ORDER BY cm.year_month))
                  / LAG(cm.total_profit) OVER (PARTITION BY cm.i_category, cm.sales_channel ORDER BY cm.year_month)) * 100
        END AS profit_mom_pct
    FROM category_monthly_agg cm
),
customer_agg AS (
    SELECT
        swd.i_category,
        swd.sales_channel,
        swd.customer_sk,
        swd.c_first_name,
        swd.c_last_name,
        swd.cd_gender,
        SUM(swd.net_profit) AS cust_total_profit
    FROM sales_with_dim swd
    GROUP BY swd.i_category, swd.sales_channel, swd.customer_sk, swd.c_first_name, swd.c_last_name, swd.cd_gender
),
top_customers_per_category AS (
    SELECT *
    FROM (
        SELECT
            ca.*,
            ROW_NUMBER() OVER (PARTITION BY i_category, sales_channel ORDER BY cust_total_profit DESC) AS rn
        FROM customer_agg ca
    ) t
    WHERE rn = 1
)
SELECT
    cm.year_month,
    cm.i_category,
    cm.sales_channel,
    cm.total_profit,
    cm.total_sales,
    cm.total_quantity,
    cm.rank_by_profit,
    ct.prev_month_profit,
    ct.profit_mom_pct,
    tc.customer_sk AS top_customer_sk,
    tc.c_first_name AS top_customer_first_name,
    tc.c_last_name AS top_customer_last_name,
    tc.cd_gender AS top_customer_gender,
    tc.cust_total_profit AS top_customer_total_profit
FROM category_monthly cm
LEFT JOIN category_trend ct
    ON cm.year_month = ct.year_month
   AND cm.i_category = ct.i_category
   AND cm.sales_channel = ct.sales_channel
LEFT JOIN top_customers_per_category tc
    ON cm.i_category = tc.i_category
   AND cm.sales_channel = tc.sales_channel
ORDER BY cm.year_month DESC, cm.total_profit DESC
LIMIT 100
