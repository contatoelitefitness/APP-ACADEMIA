-- Cole tudo isso no Supabase: SQL Editor > New query > Run

create table categorias (
  id uuid primary key default gen_random_uuid(),
  nome text not null unique
);

create table produtos (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid not null references categorias(id) on delete cascade,
  nome text not null,
  preco numeric(10,2) not null default 0,
  estoque int not null default 0 check (estoque >= 0),
  ativo boolean not null default true
);

create table vendas (
  id uuid primary key default gen_random_uuid(),
  produto_id uuid references produtos(id) on delete set null,
  produto_nome text not null,
  quantidade int not null check (quantidade > 0),
  valor_total numeric(10,2) not null,
  forma_pagamento text not null check (forma_pagamento in
    ('Pix maquininha','Pix direto (Leo)','Crédito','Débito')),
  criado_em timestamptz not null default now()  -- data e hora automáticas
);

-- Registra a venda e baixa o estoque numa única operação
create function registrar_venda(p_produto uuid, p_qtd int, p_pagamento text)
returns vendas language plpgsql security definer as $$
declare p produtos; v vendas;
begin
  update produtos set estoque = estoque - p_qtd
   where id = p_produto and estoque >= p_qtd
   returning * into p;
  if not found then raise exception 'Estoque insuficiente'; end if;
  insert into vendas (produto_id, produto_nome, quantidade, valor_total, forma_pagamento)
  values (p.id, p.nome, p_qtd, p.preco * p_qtd, p_pagamento)
  returning * into v;
  return v;
end $$;

-- Permissões (o site usa a chave "anon")
alter table categorias enable row level security;
alter table produtos   enable row level security;
alter table vendas     enable row level security;

create policy "ler categorias"  on categorias for select to anon using (true);
create policy "criar categoria" on categorias for insert to anon with check (true);
create policy "ler produtos"    on produtos   for select to anon using (true);
create policy "criar produtos"  on produtos   for insert to anon with check (true);
create policy "editar produtos" on produtos   for update to anon using (true);
create policy "ler vendas"      on vendas     for select to anon using (true);

-- Categorias iniciais
insert into categorias (nome) values
  ('Barrinhas'), ('Whey (doses)'), ('Pré-treino (doses)'), ('Creatina'), ('Térmico');
