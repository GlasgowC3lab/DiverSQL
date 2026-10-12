WITH sales_union AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_bill_customer_sk AS customer_sk,
           cs_bill_addr_sk AS addr_sk,
           cs_item_sk AS item_sk,
           cs_net_profit AS profit,
           cs_net_paid AS net_paid,
           cs_quantity AS quantity,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_customer_sk,
           ss_addr_sk,
           ss_item_sk,
           ss_net_profit,
           ss_net_paid,
           ss_quantity,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_bill_customer_sk,
           ws_bill_addr_sk,
           ws_item_sk,
           ws_net_profit,
           ws_net_paid,
           ws_quantity,
           'web'
    FROM web_sales
),
grouped_sales AS (
    SELECT
        d.d_year,
        cd.cd_gender,
        i.i_category,
        ca.ca_state,
        su.channel,
        SUM(su.profit) AS total_profit,
        SUM(su.net_paid) AS total_net_paid,
        SUM(su.quantity) AS total_quantity,
        COUNT(DISTINCT su.customer_sk) AS unique_customers,
        SUM(su.profit) / NULLIF(SUM(su.net_paid), 0) AS profit_margin
    FROM sales_union su
    JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    JOIN customer c ON su.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON su.addr_sk = ca.ca_address_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, cd.cd_gender, i.i_category, ca.ca_state, su.channel
    HAVING SUM(su.profit) > 10000
)
SELECT
    d_year,
    cd_gender,
    i_category,
    ca_state,
    channel,
    total_profit,
    total_net_paid,
    total_quantity,
    unique_customers,
    profit_margin,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
    total_profit * 100.0 / SUM(total_profit) OVER (PARTITION BY d_year) AS profit_pct_of_year
FROM grouped_sales
ORDER BY d_year, total_profit DESC
LIMIT 100
