WITH sales_union AS (
  SELECT
    ss_sold_date_sk AS date_sk,
    ss_sold_time_sk AS time_sk,
    ss_item_sk AS item_sk,
    ss_customer_sk AS customer_sk,
    ss_cdemo_sk AS cdemo_sk,
    ss_hdemo_sk AS hdemo_sk,
    ss_addr_sk AS addr_sk,
    ss_store_sk AS store_sk,
    NULL AS web_page_sk,
    NULL AS catalog_page_sk,
    ss_promo_sk AS promo_sk,
    ss_ticket_number AS ticket_number,
    ss_quantity AS quantity,
    ss_sales_price AS sales_price,
    ss_ext_sales_price AS ext_sales_price,
    ss_net_paid AS net_paid,
    ss_net_profit AS net_profit,
    'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT
    ws_sold_date_sk,
    ws_sold_time_sk,
    ws_item_sk,
    ws_bill_customer_sk,
    ws_bill_cdemo_sk,
    ws_bill_hdemo_sk,
    ws_bill_addr_sk,
    NULL,
    ws_web_page_sk,
    NULL,
    ws_promo_sk,
    ws_order_number,
    ws_quantity,
    ws_sales_price,
    ws_ext_sales_price,
    ws_net_paid,
    ws_net_profit,
    'web'
  FROM web_sales
  UNION ALL
  SELECT
    cs_sold_date_sk,
    cs_sold_time_sk,
    cs_item_sk,
    cs_bill_customer_sk,
    cs_bill_cdemo_sk,
    cs_bill_hdemo_sk,
    cs_bill_addr_sk,
    NULL,
    NULL,
    cs_catalog_page_sk,
    cs_promo_sk,
    cs_order_number,
    cs_quantity,
    cs_sales_price,
    cs_ext_sales_price,
    cs_net_paid,
    cs_net_profit,
    'catalog'
  FROM catalog_sales
),
joined AS (
  SELECT
    su.*,
    d.d_year,
    d.d_quarter_seq,
    d.d_moy
  FROM sales_union su
  LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
),
joined_item AS (
  SELECT
    j.*,
    i.i_category,
    i.i_class,
    i.i_brand,
    i.i_product_name
  FROM joined j
  LEFT JOIN item i ON j.item_sk = i.i_item_sk
),
joined_cust AS (
  SELECT
    ji.*,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_credit_rating,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
  FROM joined_item ji
  LEFT JOIN customer c ON ji.customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON ji.cdemo_sk = cd.cd_demo_sk
),
joined_promo AS (
  SELECT
    jc.*,
    p.p_promo_name,
    p.p_discount_active
  FROM joined_cust jc
  LEFT JOIN promotion p ON jc.promo_sk = p.p_promo_sk
),
aggregated AS (
  SELECT
    d_year,
    d_quarter_seq,
    i_category,
    i_brand,
    channel,
    SUM(ext_sales_price) AS total_sales,
    SUM(net_profit) AS total_profit,
    AVG(ext_sales_price / NULLIF(quantity, 0)) AS avg_price_per_unit,
    AVG(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END) AS discount_active_ratio,
    COUNT(DISTINCT customer_sk) AS distinct_customers
  FROM joined_promo
  WHERE d_year BETWEEN 1999 AND 2001
  GROUP BY d_year, d_quarter_seq, i_category, i_brand, channel
)
SELECT
  d_year,
  d_quarter_seq,
  i_category,
  i_brand,
  channel,
  total_sales,
  total_profit,
  avg_price_per_unit,
  discount_active_ratio,
  distinct_customers,
  RANK() OVER (PARTITION BY d_year, channel ORDER BY total_profit DESC) AS profit_rank_by_channel
FROM aggregated
ORDER BY d_year, d_quarter_seq, channel, total_profit DESC
LIMIT 100
