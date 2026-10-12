WITH
  cust_dim AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      cd.cd_marital_status,
      hd.hd_buy_potential,
      hd.hd_vehicle_count,
      hd.hd_dep_count,
      c.c_birth_year
    FROM customer c
    LEFT JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1970
      AND cd.cd_marital_status IN ('M', 'S')
      AND hd.hd_buy_potential = '1001-5000'
  ),

  store_sales_full AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_customer_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      p.p_promo_name,
      p.p_discount_active
    FROM store_sales ss
    FULL OUTER JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y' OR ss.ss_store_sk IS NOT NULL
  ),

  store_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      SUM(ss.ss_ext_sales_price) AS total_store_sales,
      ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS state_store_rank
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state
  ),

  catalog_cust_right AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_ext_sales_price,
      cd.c_customer_sk,
      cd.c_first_name,
      cd.c_last_name,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.hd_buy_potential,
      cd.hd_vehicle_count,
      cd.hd_dep_count
    FROM catalog_sales cs
    RIGHT JOIN cust_dim cd
      ON cs.cs_bill_customer_sk = cd.c_customer_sk
    WHERE cs.cs_ext_discount_amt > 0
  ),

  web_sales_join AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_ext_sales_price,
      ws.ws_bill_customer_sk,
      w.web_name,
      w.web_state,
      p.p_discount_active
    FROM web_sales ws
    JOIN web_site w
      ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    WHERE w.web_state = 'CA'
  )

SELECT
  cd.c_customer_sk,
  cd.c_first_name,
  cd.c_last_name,
  cd.cd_gender,
  cd.cd_marital_status,
  cd.hd_buy_potential,
  s.s_store_name,
  s.s_state,
  sa.total_store_sales,
  sa.state_store_rank,
  wsj.web_name,
  wsj.ws_ext_sales_price AS web_sales_amount,
  cc.cs_ext_sales_price AS catalog_sales_amount,
  ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(sa.total_store_sales, 0) DESC) AS gender_store_rank,
  CASE
    WHEN COALESCE(sa.total_store_sales, 0) + COALESCE(wsj.ws_ext_sales_price, 0) + COALESCE(cc.cs_ext_sales_price, 0) > 5000 THEN 'High'
    ELSE 'Low'
  END AS overall_sales_category
FROM store_sales_full ssf
LEFT JOIN store s
  ON ssf.ss_store_sk = s.s_store_sk
LEFT JOIN cust_dim cd
  ON ssf.ss_customer_sk = cd.c_customer_sk
LEFT JOIN store_agg sa
  ON s.s_store_sk = sa.s_store_sk
LEFT JOIN web_sales_join wsj
  ON cd.c_customer_sk = wsj.ws_bill_customer_sk
LEFT JOIN catalog_cust_right cc
  ON cd.c_customer_sk = cc.c_customer_sk
WHERE cd.c_customer_sk IN (
        SELECT cs_bill_customer_sk FROM catalog_sales
        INTERSECT
        SELECT ws_bill_customer_sk FROM web_sales
      )
  AND s.s_number_employees > 50
  AND cd.hd_vehicle_count >= 2
  AND cd.hd_dep_count > 0
ORDER BY overall_sales_category DESC, gender_store_rank ASC
LIMIT 100
