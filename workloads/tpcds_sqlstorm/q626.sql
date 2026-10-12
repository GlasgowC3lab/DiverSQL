WITH cust_sales AS (
   SELECT
     c.c_customer_sk,
     c.c_customer_id,
     CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
     cd.cd_gender AS gender,
     ca.ca_state,
     COALESCE(c.c_preferred_cust_flag, 'N') AS preferred_flag,
     COALESCE(SUM(ss.ss_net_profit),0) AS store_net_profit,
     COALESCE(SUM(ws.ws_net_profit),0) AS web_net_profit,
     COALESCE(SUM(cs.cs_net_profit),0) AS catalog_net_profit,
     MAX(COALESCE(d1.d_date, d2.d_date, d3.d_date)) AS last_sale_date
   FROM customer c
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
   LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
   LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
   LEFT JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
   LEFT JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
   LEFT JOIN date_dim d3 ON cs.cs_sold_date_sk = d3.d_date_sk
   GROUP BY 1,2,3,4,5,6
),
cust_returns AS (
   SELECT c_customer_sk,
          SUM(cr_net_loss) AS catalog_net_loss,
          SUM(sr_net_loss) AS store_net_loss,
          SUM(wr_net_loss) AS web_net_loss,
          SUM(cr_return_quantity) AS catalog_return_qty,
          SUM(sr_return_quantity) AS store_return_qty,
          SUM(wr_return_quantity) AS web_return_qty
   FROM (
     SELECT
       cr.cr_returning_customer_sk AS c_customer_sk,
       cr.cr_net_loss AS cr_net_loss,
       0 AS sr_net_loss,
       0 AS wr_net_loss,
       cr.cr_return_quantity AS cr_return_quantity,
       0 AS sr_return_quantity,
       0 AS wr_return_quantity
     FROM catalog_returns cr
     UNION ALL
     SELECT
       sr.sr_customer_sk AS c_customer_sk,
       0 AS cr_net_loss,
       sr.sr_net_loss AS sr_net_loss,
       0 AS wr_net_loss,
       0 AS cr_return_quantity,
       sr.sr_return_quantity AS sr_return_quantity,
       0 AS wr_return_quantity
     FROM store_returns sr
     UNION ALL
     SELECT
       wr.wr_refunded_customer_sk AS c_customer_sk,
       0 AS cr_net_loss,
       0 AS sr_net_loss,
       wr.wr_net_loss AS wr_net_loss,
       0 AS cr_return_quantity,
       0 AS sr_return_quantity,
       wr.wr_return_quantity AS wr_return_quantity
     FROM web_returns wr
   ) AS u
   GROUP BY c_customer_sk
),
cust_latest_promo AS (
    SELECT c.c_customer_sk,
           p.p_promo_name,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY p.p_start_date_sk DESC) AS rn
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name IS NOT NULL
),
ranked AS (
    SELECT
        cs.c_customer_sk,
        cs.full_name,
        cs.gender,
        cs.ca_state,
        cs.preferred_flag,
        cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit AS total_net_profit,
        (cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit) -
            COALESCE(cr.catalog_net_loss,0) -
            COALESCE(cr.store_net_loss,0) -
            COALESCE(cr.web_net_loss,0) AS adjusted_net_profit,
        cs.last_sale_date,
        CASE WHEN cs.last_sale_date IS NOT NULL THEN CAST(cs.last_sale_date AS varchar) ELSE NULL END AS last_sale_date_str,
        COALESCE(lp.p_promo_name, 'No Promo') AS latest_promo_name,
        CASE 
            WHEN (cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit) = 0 THEN 0.0
            ELSE (cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit) /
                 NULLIF((cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit) + 
                         COALESCE(cr.catalog_net_loss,0) + COALESCE(cr.store_net_loss,0) + COALESCE(cr.web_net_loss,0), 0)
        END AS profit_margin,
        CASE 
            WHEN (cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit) -
                 COALESCE(cr.catalog_net_loss,0) -
                 COALESCE(cr.store_net_loss,0) -
                 COALESCE(cr.web_net_loss,0) > 0
                 AND
                 ((cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit) /
                  NULLIF((cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit) + 
                          COALESCE(cr.catalog_net_loss,0) + COALESCE(cr.store_net_loss,0) + COALESCE(cr.web_net_loss,0), 0)) > 0.5
            THEN 'High Performer'
            WHEN (cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit) -
                 COALESCE(cr.catalog_net_loss,0) -
                 COALESCE(cr.store_net_loss,0) -
                 COALESCE(cr.web_net_loss,0) > 0
            THEN 'Performer'
            ELSE 'Low Performer'
        END AS performance_category,
        (SELECT cc.cc_name
         FROM catalog_sales cs2
         LEFT JOIN call_center cc ON cs2.cs_call_center_sk = cc.cc_call_center_sk
         WHERE cs2.cs_bill_customer_sk = cs.c_customer_sk
         ORDER BY cs2.cs_sold_date_sk DESC
         LIMIT 1) AS call_center_name,
        (SELECT ws3.ws_net_paid
         FROM web_sales ws3
         WHERE ws3.ws_bill_customer_sk = cs.c_customer_sk
         ORDER BY ws3.ws_sold_date_sk DESC
         LIMIT 1) AS latest_web_net_paid,
        ROW_NUMBER() OVER (ORDER BY (cs.store_net_profit + cs.web_net_profit + cs.catalog_net_profit) DESC) AS profit_rank
    FROM cust_sales cs
    LEFT JOIN cust_returns cr ON cs.c_customer_sk = cr.c_customer_sk
    LEFT JOIN (SELECT c_customer_sk, p_promo_name FROM cust_latest_promo WHERE rn = 1) lp ON cs.c_customer_sk = lp.c_customer_sk
    WHERE cs.preferred_flag = 'Y'
       OR cs.c_customer_sk IN (
            SELECT ss2.ss_customer_sk
            FROM store_sales ss2
            WHERE ss2.ss_quantity > 5
            AND ss2.ss_sold_date_sk IS NOT NULL
       )
)
SELECT profit_rank,
       c_customer_sk,
       full_name,
       gender,
       ca_state,
       preferred_flag,
       total_net_profit,
       adjusted_net_profit,
       profit_margin,
       last_sale_date_str,
       latest_promo_name,
       performance_category,
       call_center_name,
       latest_web_net_paid
FROM (
    SELECT *
    FROM ranked
    WHERE profit_rank <= 50
) hp
INTERSECT
SELECT profit_rank,
       c_customer_sk,
       full_name,
       gender,
       ca_state,
       preferred_flag,
       total_net_profit,
       adjusted_net_profit,
       profit_margin,
       last_sale_date_str,
       latest_promo_name,
       performance_category,
       call_center_name,
       latest_web_net_paid
FROM (
    SELECT *
    FROM ranked
    WHERE c_customer_sk IN (
        SELECT c_customer_sk
        FROM cust_returns
        WHERE catalog_net_loss > 0 OR store_net_loss > 0 OR web_net_loss > 0
    )
) rc
ORDER BY profit_rank
