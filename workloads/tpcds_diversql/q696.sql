/*
  Goal: Identify top‑performing sales orders and aggregate sales by store and call center, while demonstrating deep joins, full outer join, INTERSECT, UNION, CTEs, LATERAL subqueries and pagination.
*/
WITH sales_base AS (
   SELECT
     cs.cs_order_number,
     cs.cs_sold_date_sk    AS sold_date_sk,
     cs.cs_ship_date_sk    AS ship_date_sk,
     cs.cs_bill_customer_sk,
     cs.cs_ship_customer_sk,
     cs.cs_call_center_sk,
     cs.cs_item_sk,
     cs.cs_quantity,
     cs.cs_net_paid,
     cs.cs_net_profit,
     d_sold.d_year         AS sold_year
   FROM catalog_sales cs
   JOIN date_dim d_sold      ON cs.cs_sold_date_sk  = d_sold.d_date_sk
   JOIN date_dim d_ship      ON cs.cs_ship_date_sk  = d_ship.d_date_sk
   JOIN customer cust_bill   ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
   JOIN customer cust_ship   ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
   JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
   JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
store_cc_full AS (
   SELECT
     s.s_store_id,
     cc.cc_name,
     s.s_closed_date_sk
   FROM store s
   FULL OUTER JOIN call_center cc
     ON s.s_closed_date_sk = cc.cc_closed_date_sk
),
intersect_orders AS (
   SELECT cs_order_number FROM catalog_sales WHERE cs_net_profit > 1000
   INTERSECT
   SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 100
)
SELECT
  entity_name,
  metric1,
  metric2,
  extra1,
  extra2
FROM (
   /* First branch – store level detail */
   SELECT
     s.s_store_id                     AS entity_name,
     sb.cs_net_paid                   AS metric1,
     sb.cs_quantity                   AS metric2,
     r_desc.r_reason_desc             AS extra1,
     NULL                             AS extra2
   FROM sales_base sb
   JOIN store s ON sb.sold_date_sk = s.s_closed_date_sk
   LEFT JOIN LATERAL (
       SELECT SUM(cr.cr_return_amount) AS total_return_amount
       FROM catalog_returns cr
       WHERE cr.cr_order_number = sb.cs_order_number
   ) rtn ON TRUE
   LEFT JOIN LATERAL (
       SELECT r.r_reason_desc
       FROM catalog_returns cr
       JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
       WHERE cr.cr_order_number = sb.cs_order_number
       ORDER BY cr.cr_return_amount DESC
       LIMIT 1
   ) r_desc ON TRUE
   WHERE sb.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)

   UNION DISTINCT

   /* Second branch – call‑center level aggregation */
   SELECT
     cc.cc_name                       AS entity_name,
     SUM(sb.cs_net_paid)              AS metric1,
     COUNT(DISTINCT sb.cs_order_number) AS metric2,
     NULL                             AS extra1,
     NULL                             AS extra2
   FROM sales_base sb
   JOIN call_center cc ON sb.cs_call_center_sk = cc.cc_call_center_sk
   WHERE sb.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
   GROUP BY cc.cc_name
) final_result
ORDER BY metric1 DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
