/*
  Goal: Aggregate total sales and order counts by year and return reason across the catalog and web channels.
  The query demonstrates deep joins across all 13 selected TPC‑DS tables, re‑uses dimensions under different aliases,
  includes a FULL OUTER JOIN, expands a derived array with UNNEST, and combines two sub‑queries with UNION DISTINCT.
*/
SELECT
    year,
    reason_desc,
    total_sales,
    orders
FROM (
    /* ---------- Catalog channel ---------- */
    SELECT
        d.d_year               AS year,
        r.r_reason_desc        AS reason_desc,
        SUM(cs.cs_net_paid)    AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    FULL OUTER JOIN inventory inv
        ON inv.inv_item_sk = cs.cs_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    /* Expand a derived array containing the item key */
    CROSS JOIN UNNEST(array[cs.cs_item_sk]) AS u(item_sk)
    GROUP BY d.d_year, r.r_reason_desc

    UNION DISTINCT

    /* ---------- Web channel ---------- */
    SELECT
        d2.d_year               AS year,
        r2.r_reason_desc        AS reason_desc,
        SUM(ws.ws_net_paid)    AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_dim d2
        ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2
        ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN customer_demographics cd2
        ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2
        ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r2
        ON wr.wr_reason_sk = r2.r_reason_sk
    FULL OUTER JOIN inventory inv2
        ON inv2.inv_item_sk = ws.ws_item_sk
       AND inv2.inv_warehouse_sk = w2.w_warehouse_sk
    /* Expand a derived array containing the item key */
    CROSS JOIN UNNEST(array[ws.ws_item_sk]) AS u2(item_sk)
    GROUP BY d2.d_year, r2.r_reason_desc
) AS combined
ORDER BY year DESC, total_sales DESC
LIMIT 100
