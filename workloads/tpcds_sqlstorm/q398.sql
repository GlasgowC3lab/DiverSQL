WITH unified_sales AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_promo_sk AS promo_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_promo_sk AS promo_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           'web' AS channel
    FROM web_sales ws
),
enriched_sales AS (
    SELECT us.*,
           d.d_year,
           i.i_category,
           i.i_class,
           i.i_brand,
           i.i_item_id,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           p.p_discount_active
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.date_sk = d.d_date_sk
    LEFT JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN customer c ON us.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
),
agg_sales AS (
    SELECT d_year,
           channel,
           i_category,
           i_class,
           cd_gender,
           cd_marital_status,
           SUM(net_paid) AS total_net_paid,
           SUM(net_profit) AS total_net_profit,
           SUM(quantity) AS total_quantity,
           COUNT(DISTINCT customer_sk) AS distinct_customers,
           SUM(CASE WHEN p_discount_active = 'Y' THEN net_paid ELSE 0 END) AS discount_active_net_paid
    FROM enriched_sales
    GROUP BY d_year,
             channel,
             i_category,
             i_class,
             cd_gender,
             cd_marital_status
),
ranked_sales AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY i_category, d_year ORDER BY total_net_profit DESC) AS profit_rank,
           LAG(total_net_profit) OVER (PARTITION BY i_category ORDER BY d_year) AS prev_year_profit
    FROM agg_sales
)
SELECT d_year,
       channel,
       i_category,
       i_class,
       cd_gender,
       cd_marital_status,
       total_net_paid,
       total_net_profit,
       total_quantity,
       distinct_customers,
       discount_active_net_paid,
       profit_rank,
       CASE WHEN prev_year_profit IS NULL OR prev_year_profit = 0 THEN NULL
            ELSE (total_net_profit - prev_year_profit) / prev_year_profit
       END AS yoy_profit_growth
FROM ranked_sales
WHERE profit_rank <= 5
ORDER BY d_year DESC, i_category, profit_rank
