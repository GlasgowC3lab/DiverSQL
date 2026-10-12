WITH
sales_store AS (
   SELECT
       ss.ss_item_sk AS i_item_sk,
       i.i_product_name AS i_product_name,
       d.d_year,
       d.d_quarter_seq,
       SUM(ss.ss_net_profit) AS profit,
       SUM(COALESCE(p.p_cost, 0)) AS promo_cost,
       COUNT(*) AS cnt_sales
   FROM store_sales ss
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY ss.ss_item_sk, i.i_product_name, d.d_year, d.d_quarter_seq
),
sales_web AS (
   SELECT
       ws.ws_item_sk AS i_item_sk,
       i.i_product_name AS i_product_name,
       d.d_year,
       d.d_quarter_seq,
       SUM(ws.ws_net_profit) AS profit,
       SUM(COALESCE(p.p_cost, 0)) AS promo_cost,
       COUNT(*) AS cnt_sales
   FROM web_sales ws
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   GROUP BY ws.ws_item_sk, i.i_product_name, d.d_year, d.d_quarter_seq
),
sales_catalog AS (
   SELECT
       cs.cs_item_sk AS i_item_sk,
       i.i_product_name AS i_product_name,
       d.d_year,
       d.d_quarter_seq,
       SUM(cs.cs_net_profit) AS profit,
       SUM(COALESCE(p.p_cost, 0)) AS promo_cost,
       COUNT(*) AS cnt_sales
   FROM catalog_sales cs
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   GROUP BY cs.cs_item_sk, i.i_product_name, d.d_year, d.d_quarter_seq
),
sales_union AS (
   SELECT * FROM sales_store
   UNION ALL
   SELECT * FROM sales_web
   UNION ALL
   SELECT * FROM sales_catalog
),
sales_agg AS (
   SELECT
       i_item_sk,
       i_product_name,
       d_year,
       d_quarter_seq,
       SUM(profit) AS total_profit,
       SUM(promo_cost) AS total_promo_cost,
       SUM(cnt_sales) AS total_sales_cnt
   FROM sales_union
   GROUP BY i_item_sk, i_product_name, d_year, d_quarter_seq
),
returns_store AS (
   SELECT
       sr.sr_item_sk AS i_item_sk,
       i.i_product_name AS i_product_name,
       d.d_year,
       d.d_quarter_seq,
       SUM(sr.sr_net_loss) AS total_loss,
       COUNT(*) AS cnt_returns
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   GROUP BY sr.sr_item_sk, i.i_product_name, d.d_year, d.d_quarter_seq
),
returns_web AS (
   SELECT
       wr.wr_item_sk AS i_item_sk,
       i.i_product_name AS i_product_name,
       d.d_year,
       d.d_quarter_seq,
       SUM(wr.wr_net_loss) AS total_loss,
       COUNT(*) AS cnt_returns
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   GROUP BY wr.wr_item_sk, i.i_product_name, d.d_year, d.d_quarter_seq
),
returns_catalog AS (
   SELECT
       cr.cr_item_sk AS i_item_sk,
       i.i_product_name AS i_product_name,
       d.d_year,
       d.d_quarter_seq,
       SUM(cr.cr_net_loss) AS total_loss,
       COUNT(*) AS cnt_returns
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   GROUP BY cr.cr_item_sk, i.i_product_name, d.d_year, d.d_quarter_seq
),
returns_union AS (
   SELECT * FROM returns_store
   UNION ALL
   SELECT * FROM returns_web
   UNION ALL
   SELECT * FROM returns_catalog
),
returns_agg AS (
   SELECT
       i_item_sk,
       i_product_name,
       d_year,
       d_quarter_seq,
       SUM(total_loss) AS total_loss,
       SUM(cnt_returns) AS total_cnt_returns
   FROM returns_union
   GROUP BY i_item_sk, i_product_name, d_year, d_quarter_seq
)
SELECT
    t.i_item_sk,
    t.i_product_name,
    t.d_year,
    t.d_quarter_seq,
    t.total_sales_cnt,
    t.total_cnt_returns,
    t.total_profit,
    t.total_promo_cost,
    t.total_loss,
    t.net_profit,
    t.avg_profit_per_sale,
    t.profit_rank
FROM (
    SELECT
        s.i_item_sk,
        s.i_product_name,
        s.d_year,
        s.d_quarter_seq,
        s.total_sales_cnt,
        COALESCE(r.total_cnt_returns, 0) AS total_cnt_returns,
        s.total_profit,
        s.total_promo_cost,
        COALESCE(r.total_loss, 0) AS total_loss,
        (s.total_profit - s.total_promo_cost - COALESCE(r.total_loss, 0)) AS net_profit,
        ROUND((s.total_profit - s.total_promo_cost - COALESCE(r.total_loss, 0)) / NULLIF(s.total_sales_cnt, 0), 2) AS avg_profit_per_sale,
        ROW_NUMBER() OVER (PARTITION BY s.d_year, s.d_quarter_seq ORDER BY (s.total_profit - s.total_promo_cost - COALESCE(r.total_loss, 0)) DESC) AS profit_rank
    FROM sales_agg s
    LEFT JOIN returns_agg r
      ON s.i_item_sk = r.i_item_sk
     AND s.d_year = r.d_year
     AND s.d_quarter_seq = r.d_quarter_seq
    WHERE (s.total_profit - s.total_promo_cost - COALESCE(r.total_loss, 0)) > 0
) t
WHERE t.profit_rank <= 10
ORDER BY t.d_year, t.d_quarter_seq, t.profit_rank
