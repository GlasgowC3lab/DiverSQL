WITH
  sales_agg AS (
    SELECT
      ws_item_sk,
      ws_bill_hdemo_sk,
      SUM(ws_net_paid) AS total_net_paid,
      COUNT(*)    AS cnt_sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2000
    )
    GROUP BY ws_item_sk, ws_bill_hdemo_sk
  ),

  returns_agg AS (
    SELECT
      wr_item_sk,
      wr_returned_date_sk,
      SUM(wr_return_amt) AS total_return_amt,
      COUNT(*)          AS cnt_ret
    FROM web_returns
    WHERE wr_returned_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2000
    )
    GROUP BY wr_item_sk, wr_returned_date_sk
  ),

  sampled_site AS (
    SELECT *
    FROM web_site TABLESAMPLE BERNOULLI (10)
  ),

  customers_with_sales AS (
    SELECT DISTINCT ws_bill_customer_sk AS c_customer_sk
    FROM web_sales
  ),

  customers_with_returns AS (
    SELECT DISTINCT wr_refunded_customer_sk AS c_customer_sk
    FROM web_returns
  ),

  sales_not_return_customers AS (
    SELECT c_customer_sk
    FROM customers_with_sales
    EXCEPT
    SELECT c_customer_sk
    FROM customers_with_returns
  )
,

  unioned AS (
    SELECT
      c.c_customer_id,
      d.d_year,
      ib.ib_lower_bound,
      sa.total_net_paid,
      ra.total_return_amt,
      (sns.c_customer_sk IS NOT NULL)               AS has_sales_no_return,
      grp_set.grp_id
    FROM sales_agg sa
    JOIN web_sales ws ON ws.ws_item_sk = sa.ws_item_sk
                       AND ws.ws_bill_hdemo_sk = sa.ws_bill_hdemo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN sampled_site s ON ws.ws_web_site_sk = s.web_site_sk
    LEFT JOIN returns_agg ra ON ra.wr_item_sk = sa.ws_item_sk
    LEFT JOIN sales_not_return_customers sns ON sns.c_customer_sk = c.c_customer_sk
    CROSS JOIN (VALUES 1, 2) AS grp_set (grp_id)
    WHERE EXISTS (
            SELECT 1
            FROM date_dim d2
            WHERE d2.d_date_sk = c.c_first_sales_date_sk
              AND d2.d_year = 2000
          )
  ),

  unioned2 AS (
    SELECT
      c.c_customer_id,
      d.d_year,
      ib.ib_lower_bound,
      sa.total_net_paid,
      ra.total_return_amt,
      FALSE                                          AS has_sales_no_return,
      grp_set.grp_id
    FROM sales_agg sa
    JOIN web_sales ws ON ws.ws_item_sk = sa.ws_item_sk
                       AND ws.ws_bill_hdemo_sk = sa.ws_bill_hdemo_sk
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk   -- ship role
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN returns_agg ra ON ra.wr_item_sk = sa.ws_item_sk
    CROSS JOIN (VALUES 1, 2) AS grp_set (grp_id)
    WHERE c.c_preferred_cust_flag = 'Y'
  )

SELECT *
FROM (
  SELECT * FROM unioned
  UNION DISTINCT
  SELECT * FROM unioned2
) final_result
ORDER BY c_customer_id, d_year DESC, grp_id
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
