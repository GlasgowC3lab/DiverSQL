select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 769 and 769+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'purple') and 
        (i_units = 'Pound' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'yellow' or i_color = 'coral') and
        (i_units = 'Unknown' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'white') and
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'violet') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'green') and 
        (i_units = 'Tbl' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'lawn') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'moccasin') and
        (i_units = 'Bunch' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'lace') and
        (i_units = 'Lb' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100
