WITH store_agg AS (
   SELECT ss.ss_customer_sk AS customer_sk,
          d.d_year AS year,
          SUM(ss.ss_net_paid) AS total_net_paid
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY ss.ss_customer_sk, d.d_year
),
store_top AS (
   SELECT customer_sk, year, total_net_paid
   FROM (
        SELECT customer_sk,
               year,
               total_net_paid,
               ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_paid DESC) AS rn
        FROM store_agg
   )
   WHERE rn <= 3
),
web_agg AS (
   SELECT ws.ws_bill_customer_sk AS customer_sk,
          d.d_year AS year,
          SUM(ws.ws_net_paid) AS total_net_paid
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   GROUP BY ws.ws_bill_customer_sk, d.d_year
),
web_top AS (
   SELECT customer_sk, year, total_net_paid
   FROM (
        SELECT customer_sk,
               year,
               total_net_paid,
               ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_paid DESC) AS rn
        FROM web_agg
   )
   WHERE rn <= 3
),
common_customers AS (
   SELECT customer_sk, year
   FROM store_top
   INTERSECT
   SELECT customer_sk, year
   FROM web_top
)
SELECT final.customer_sk,
       final.year,
       final.store_total,
       final.web_total,
       final.rn
FROM (
   SELECT st.customer_sk,
          st.year,
          st.total_net_paid AS store_total,
          wt.total_net_paid AS web_total,
          ROW_NUMBER() OVER (PARTITION BY st.year ORDER BY (st.total_net_paid + wt.total_net_paid) DESC) AS rn
   FROM common_customers cc
   JOIN store_top st ON cc.customer_sk = st.customer_sk AND cc.year = st.year
   JOIN web_top   wt ON cc.customer_sk = wt.customer_sk AND cc.year = wt.year
) final
WHERE final.rn <= 3
ORDER BY final.year DESC, final.rn
LIMIT 100
