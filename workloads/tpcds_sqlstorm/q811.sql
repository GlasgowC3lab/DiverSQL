WITH web AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           SUM(ws.ws_ext_sales_price) AS web_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_category IN ('Sports','Clothing','Home')
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
), store AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           SUM(ss.ss_ext_sales_price) AS store_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_category IN ('Sports','Clothing','Home')
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
), catalog AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           SUM(cs.cs_ext_sales_price) AS catalog_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_category IN ('Sports','Clothing','Home')
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
), combined AS (
    SELECT COALESCE(w.d_year, s.d_year, c.d_year) AS d_year,
           COALESCE(w.d_month_seq, s.d_month_seq, c.d_month_seq) AS d_month_seq,
           COALESCE(w.i_category, s.i_category, c.i_category) AS i_category,
           COALESCE(w.i_brand, s.i_brand, c.i_brand) AS i_brand,
           COALESCE(w.web_sales, 0) AS web_sales,
           COALESCE(s.store_sales, 0) AS store_sales,
           COALESCE(c.catalog_sales, 0) AS catalog_sales
    FROM web w
    FULL OUTER JOIN store s
      ON w.d_year = s.d_year
     AND w.d_month_seq = s.d_month_seq
     AND w.i_category = s.i_category
     AND w.i_brand = s.i_brand
    FULL OUTER JOIN catalog c
      ON COALESCE(w.d_year, s.d_year) = c.d_year
     AND COALESCE(w.d_month_seq, s.d_month_seq) = c.d_month_seq
     AND COALESCE(w.i_category, s.i_category) = c.i_category
     AND COALESCE(w.i_brand, s.i_brand) = c.i_brand
)
SELECT d_year,
       d_month_seq,
       i_category,
       i_brand,
       web_sales,
       store_sales,
       catalog_sales,
       (web_sales + store_sales + catalog_sales) AS total_sales,
       ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY (web_sales + store_sales + catalog_sales) DESC) AS rank_in_category
FROM combined
WHERE (web_sales + store_sales + catalog_sales) > 0
ORDER BY d_year, i_category, rank_in_category
LIMIT 100
