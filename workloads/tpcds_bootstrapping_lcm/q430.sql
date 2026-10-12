SELECT
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS rank,
    return_date,
    d_year,
    d_month_seq,
    s_store_id,
    s_store_name,
    web_site_id,
    web_name,
    catalog_return_orders,
    web_return_orders,
    catalog_total_return_amount,
    web_total_return_amount,
    catalog_total_net_loss,
    web_total_net_loss,
    total_net_loss,
    total_return_tax,
    avg_store_tax_percentage,
    avg_website_tax_percentage
FROM (
    SELECT
        d.d_date AS return_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        ws.web_site_id,
        ws.web_name,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(cr.cr_return_amount) AS catalog_total_return_amount,
        SUM(wr.wr_return_amt) AS web_total_return_amount,
        SUM(cr.cr_net_loss) AS catalog_total_net_loss,
        SUM(wr.wr_net_loss) AS web_total_net_loss,
        SUM(cr.cr_return_tax) + SUM(wr.wr_return_tax) AS total_return_tax,
        (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
        AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
        AVG(ws.web_tax_percentage) AS avg_website_tax_percentage
    FROM date_dim d
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        ws.web_site_id,
        ws.web_name
) t
ORDER BY total_net_loss DESC
LIMIT 100
