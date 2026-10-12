WITH base_sales AS (
   SELECT
      ss.ss_sold_date_sk AS date_sk,
      ss.ss_store_sk AS store_sk,
      ss.ss_customer_sk AS cust_sk,
      ss.ss_item_sk AS item_sk,
      ss.ss_promo_sk AS promo_sk,
      ss.ss_cdemo_sk AS cdemo_sk,
      ss.ss_hdemo_sk AS hdemo_sk,
      ss.ss_quantity AS quantity,
      ss.ss_ext_sales_price AS ext_sales_price,
      ss.ss_net_profit AS net_profit
   FROM store_sales ss
),
sales_date AS (
   SELECT
      bs.*,
      d.d_year AS sales_year,
      d.d_month_seq,
      d.d_week_seq,
      d.d_date
   FROM base_sales bs
   JOIN date_dim d ON bs.date_sk = d.d_date_sk
),
sales_store AS (
   SELECT
      sd.*,
      s.s_store_name,
      s.s_state,
      s.s_city,
      s.s_tax_percentage
   FROM sales_date sd
   JOIN store s ON sd.store_sk = s.s_store_sk
),
sales_item AS (
   SELECT
      ss.*,
      i.i_category,
      i.i_brand,
      i.i_product_name,
      i.i_color,
      i.i_size
   FROM sales_store ss
   JOIN item i ON ss.item_sk = i.i_item_sk
),
sales_promo AS (
   SELECT
      si.*,
      p.p_promo_name,
      p.p_discount_active
   FROM sales_item si
   LEFT JOIN promotion p ON si.promo_sk = p.p_promo_sk
),
sales_cdemo AS (
   SELECT
      sp.*,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_education_status,
      cd.cd_credit_rating
   FROM sales_promo sp
   LEFT JOIN customer_demographics cd ON sp.cdemo_sk = cd.cd_demo_sk
),
sales_hdemo AS (
   SELECT
      sc.*,
      hd.hd_buy_potential,
      hd.hd_income_band_sk
   FROM sales_cdemo sc
   LEFT JOIN household_demographics hd ON sc.hdemo_sk = hd.hd_demo_sk
)
SELECT
   sales_year,
   s_state,
   i_category,
   SUM(ext_sales_price) AS total_sales,
   SUM(net_profit) AS total_profit,
   SUM(quantity) AS total_quantity,
   COUNT(DISTINCT cust_sk) AS unique_customers,
   AVG(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_active_ratio,
   SUM(CASE WHEN cd_gender = 'M' THEN ext_sales_price ELSE 0 END) AS male_sales,
   SUM(CASE WHEN cd_gender = 'F' THEN ext_sales_price ELSE 0 END) AS female_sales,
   SUM(CASE WHEN hd_buy_potential = 'HIGH' THEN ext_sales_price ELSE 0 END) AS high_potential_sales
FROM sales_hdemo
WHERE sales_year BETWEEN 1999 AND 2002
GROUP BY sales_year, s_state, i_category
ORDER BY sales_year, s_state, total_sales DESC
LIMIT 100
