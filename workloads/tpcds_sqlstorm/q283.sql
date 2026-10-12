SELECT d.d_year,
       i.i_category,
       i.i_brand,
       SUM(s.sales_amount) AS total_sales,
       SUM(s.sales_tax) AS total_tax,
       SUM(s.net_profit) AS total_profit,
       COALESCE(SUM(r.return_amount), 0) AS total_return_amount,
       COALESCE(SUM(r.net_loss), 0) AS total_return_loss
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_ext_sales_price AS sales_amount,
           cs.cs_ext_tax AS sales_tax,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs

    UNION ALL

    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_ext_sales_price,
           ss.ss_ext_tax,
           ss.ss_net_profit
    FROM store_sales ss

    UNION ALL

    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_ext_sales_price,
           ws.ws_ext_tax,
           ws.ws_net_profit
    FROM web_sales ws
) s
LEFT JOIN (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_amount AS return_amount,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr

    UNION ALL

    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_return_amt,
           sr.sr_net_loss
    FROM store_returns sr

    UNION ALL

    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_return_amt,
           wr.wr_net_loss
    FROM web_returns wr
) r ON s.date_sk = r.date_sk AND s.item_sk = r.item_sk
JOIN item i ON s.item_sk = i.i_item_sk
JOIN date_dim d ON s.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, i.i_category, i.i_brand
ORDER BY d.d_year, i.i_category, i.i_brand
