PGDMP  -    	            
    {            NANAMI    16.0    16.0 v    W           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            X           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            Y           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            Z           1262    41570    NANAMI    DATABASE        CREATE DATABASE "NANAMI" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Spanish_Venezuela.1252';
    DROP DATABASE "NANAMI";
                postgres    false            s           1247    41611    tipo_aplicacion_domain    DOMAIN     c  CREATE DOMAIN public.tipo_aplicacion_domain AS character varying(20)
	CONSTRAINT tipo_aplicacion_domain_check CHECK (((VALUE)::text = ANY ((ARRAY['Juegos'::character varying, 'Cocina'::character varying, 'Lectura'::character varying, 'Entretenimiento'::character varying, 'Educación'::character varying, 'Fotos y Videos'::character varying])::text[])));
 +   DROP DOMAIN public.tipo_aplicacion_domain;
       public          postgres    false            �           1247    41659    tipo_cancion_domain    DOMAIN     �  CREATE DOMAIN public.tipo_cancion_domain AS character varying(20)
	CONSTRAINT tipo_cancion_domain_check CHECK (((VALUE)::text = ANY ((ARRAY['Pop'::character varying, 'Balada'::character varying, 'Rock'::character varying, 'R&B'::character varying, 'Alternativa'::character varying, 'Electronica'::character varying, 'HipHop'::character varying, 'Punk'::character varying, 'PopRock'::character varying, 'EDM'::character varying, 'House'::character varying])::text[])));
 (   DROP DOMAIN public.tipo_cancion_domain;
       public          postgres    false            �            1255    41766    fn_check_dispositivo()    FUNCTION     �  CREATE FUNCTION public.fn_check_dispositivo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   IF new.id_producto NOT IN (SELECT id_producto FROM aplicacion) THEN
      RETURN NEW;
   END IF;

   IF (
      SELECT COUNT(*)
      FROM (
         SELECT *
         FROM compra 
         JOIN dispositivo ON compra.id = new.id AND dispositivo.id_producto = compra.id_producto  
      ) AS unidas
      JOIN aplicacion ON aplicacion.id_producto = new.id_producto
      WHERE CAST(REPLACE(aplicacion.version_ios, '.', '') AS INTEGER) <= CAST(REPLACE(unidas.version_ios, '.', '') AS INTEGER) + 1
   ) <> 0 THEN
      RETURN NEW;
   ELSE
      RAISE EXCEPTION 'No hay dispositivo compatible con la aplicación.';
   END IF;

   RETURN NEW;
END;
$$;
 -   DROP FUNCTION public.fn_check_dispositivo();
       public          postgres    false            �            1255    41768    fn_check_dispositivo_true()    FUNCTION     �  CREATE FUNCTION public.fn_check_dispositivo_true() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   IF (
     (
            SELECT COUNT(*)
            FROM compra 
            JOIN dispositivo ON compra.id = new.id and compra.id_producto=dispositivo.id_producto
         ) = 0 and new.id_producto IN (SELECT id_producto FROM aplicacion)
   ) THEN
      RAISE EXCEPTION 'Usted no tiene dispositivo.';
   END IF;

   RETURN NEW;
END;
$$;
 2   DROP FUNCTION public.fn_check_dispositivo_true();
       public          postgres    false                        1255    41774    fn_check_duracion()    FUNCTION     �   CREATE FUNCTION public.fn_check_duracion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 NEW.duracion = NEW.fecha_fin - NEW.fecha_inicio;
  RETURN NEW;
END;
$$;
 *   DROP FUNCTION public.fn_check_duracion();
       public          postgres    false            �            1255    41770    fn_check_monto()    FUNCTION     �   CREATE FUNCTION public.fn_check_monto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

  NEW.monto = (
    SELECT costo
    FROM producto
    WHERE id_producto = NEW.id_producto
  );

  RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.fn_check_monto();
       public          postgres    false            �            1255    41772    fn_check_monto_descuento()    FUNCTION     �  CREATE FUNCTION public.fn_check_monto_descuento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
if NEW.id_promo is not NULL then 
  IF EXISTS (
    SELECT 1
    FROM promocion
    INNER JOIN promousuario ON promocion.id_promo = promousuario.id_promo
    WHERE promousuario.id = NEW.id AND promocion.fecha_inicio < NEW.fecha_compra AND promocion.fecha_fin > NEW.fecha_compra
  ) Then


      NEW.monto:= NEW.monto - (NEW.monto * (30 + (SELECT descuento FROM promocion WHERE id_promo = NEW.id_promo)) / 100);
else 
 NEW.monto:= NEW.monto - (NEW.monto * (SELECT descuento FROM promocion WHERE id_promo = NEW.id_promo) / 100);
  END IF;
   END IF;

IF  (NEW.id_promo is NULL)  then
 
  IF  0<(
    SELECT count (*)
    FROM promocion
    INNER JOIN promousuario ON promocion.id_promo = promousuario.id_promo
    WHERE promousuario.id = NEW.id AND promocion.fecha_inicio < NEW.fecha_compra AND promocion.fecha_fin > NEW.fecha_compra
  ) Then
   NEW.monto:= NEW.monto - (NEW.monto * 30 / 100);
END IF;
  END IF;
  UPDATE compra 
  SET monto = NEW.monto
  WHERE fecha_compra = NEW.fecha_compra AND id_producto = NEW.id_producto AND id = NEW.id ;

  RETURN NEW;
END;
$$;
 1   DROP FUNCTION public.fn_check_monto_descuento();
       public          postgres    false            �            1255    41764    fn_check_pais()    FUNCTION     g  CREATE FUNCTION public.fn_check_pais() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF (new.id_promo<>null and
        (SELECT pais_usuario FROM Usuario WHERE id = NEW.id) IS DISTINCT FROM
        (SELECT pais FROM Paises WHERE id_promo = NEW.id_promo)   OR
        NEW.fecha_compra > (SELECT fecha_fin FROM Promocion WHERE id_promo = NEW.id_promo ) or  NEW.fecha_compra < (SELECT fecha_inicio FROM Promocion WHERE id_promo = NEW.id_promo )
    ) THEN
        RAISE EXCEPTION 'El usuario no tiene el mismo país que la promoción o ya se acabó la promoción.';


    END IF;

    RETURN NEW;
END;
$$;
 &   DROP FUNCTION public.fn_check_pais();
       public          postgres    false            �            1255    41762    fn_check_puntuacion()    FUNCTION     )  CREATE FUNCTION public.fn_check_puntuacion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE producto
    SET puntuacion = (
        SELECT AVG(rating) 
        FROM compra
        WHERE id_producto = NEW.id_producto
    )
    WHERE id_producto = NEW.id_producto;
RETURN NEW;
END;
$$;
 ,   DROP FUNCTION public.fn_check_puntuacion();
       public          postgres    false                       1255    41776    fn_check_und_vendidas()    FUNCTION     )  CREATE FUNCTION public.fn_check_und_vendidas() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE cancion
    SET und_vendidas = (
        SELECT count(*) 
        FROM compra
        WHERE id_producto = NEW.id_producto
    )
    WHERE id_producto = NEW.id_producto;
RETURN NEW;
END;
$$;
 .   DROP FUNCTION public.fn_check_und_vendidas();
       public          postgres    false            �            1255    41760    trf_insert_promo_incentivo()    FUNCTION     L  CREATE FUNCTION public.trf_insert_promo_incentivo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	n_de_compras integer := 0;
	p_fecha_inicio date:= NEW.fecha_compra;
	p_fecha_fin date;
	p_duracion integer;
	p_id_promo integer;
BEGIN
SELECT COUNT(*)
	FROM promocion
	INTO p_id_promo;
	SELECT COUNT(*)
	FROM compra
	WHERE compra.id = NEW.id
	INTO n_de_compras;
	
	IF  n_de_compras <>0 and (n_de_compras % 3)=0 THEN
		p_fecha_fin := p_fecha_inicio + CAST('1 month' AS INTERVAL);
		p_duracion := p_fecha_fin - p_fecha_inicio;
		INSERT INTO promocion ( id_promo,descuento, duracion, fecha_fin, fecha_inicio)
		VALUES ( p_id_promo +1, 30, p_duracion,p_fecha_fin,p_fecha_inicio )
		RETURNING id_promo INTO p_id_promo;
		
		INSERT INTO PromoUsuario (id_promo, id)
		VALUES ( p_id_promo,NEW.id);
		RETURN NEW;
		END IF;
RETURN NEW;
END
			$$;
 3   DROP FUNCTION public.trf_insert_promo_incentivo();
       public          postgres    false            �            1259    41614 
   aplicacion    TABLE     F  CREATE TABLE public.aplicacion (
    id_producto integer NOT NULL,
    tamano_mb integer,
    version character varying(8),
    nombre character varying(50),
    descripcion character varying(1000),
    version_ios character varying(8),
    semantica public.tipo_aplicacion_domain,
    id integer,
    CONSTRAINT aplicacion_version_ios_check CHECK (((version_ios)::text ~ '^[0-9]+\.[0-9]+\.[0-9]+$'::text)),
    CONSTRAINT aplicacion_version_ios_check1 CHECK (((version_ios)::text ~ '^[0-9]+\.[0-9]+\.[0-9]+$'::text)),
    CONSTRAINT chk_tamanoaplicacion CHECK ((tamano_mb > 0))
);
    DROP TABLE public.aplicacion;
       public         heap    postgres    false    883            �            1259    41613    aplicacion_id_producto_seq    SEQUENCE     �   CREATE SEQUENCE public.aplicacion_id_producto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.aplicacion_id_producto_seq;
       public          postgres    false    223            [           0    0    aplicacion_id_producto_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.aplicacion_id_producto_seq OWNED BY public.aplicacion.id_producto;
          public          postgres    false    222            �            1259    41646    artista    TABLE     �   CREATE TABLE public.artista (
    id_artista integer NOT NULL,
    nom_artistico character varying(50),
    fecha_inicio date,
    fecha_fin date,
    nombre character varying(50)
);
    DROP TABLE public.artista;
       public         heap    postgres    false            �            1259    41645    artista_id_artista_seq    SEQUENCE     �   CREATE SEQUENCE public.artista_id_artista_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.artista_id_artista_seq;
       public          postgres    false    226            \           0    0    artista_id_artista_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.artista_id_artista_seq OWNED BY public.artista.id_artista;
          public          postgres    false    225            �            1259    41662    cancion    TABLE     }  CREATE TABLE public.cancion (
    id_producto integer NOT NULL,
    und_vendidas integer,
    nom_cancion character varying(50),
    fecha_lanz date,
    duracion time without time zone,
    nom_disco character varying(50),
    genero public.tipo_cancion_domain,
    id_artista integer,
    CONSTRAINT chk_duracioncancion CHECK ((duracion > '00:00:00'::time without time zone))
);
    DROP TABLE public.cancion;
       public         heap    postgres    false    896            �            1259    41661    cancion_id_producto_seq    SEQUENCE     �   CREATE SEQUENCE public.cancion_id_producto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.cancion_id_producto_seq;
       public          postgres    false    228            ]           0    0    cancion_id_producto_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.cancion_id_producto_seq OWNED BY public.cancion.id_producto;
          public          postgres    false    227            �            1259    41635    casadisquera    TABLE     �   CREATE TABLE public.casadisquera (
    nombre character varying(50) NOT NULL,
    av_casad character varying(50),
    ciudad_casad character varying(50)
);
     DROP TABLE public.casadisquera;
       public         heap    postgres    false            �            1259    41592    ciudad    TABLE     l   CREATE TABLE public.ciudad (
    ciudad character varying(50) NOT NULL,
    estado character varying(50)
);
    DROP TABLE public.ciudad;
       public         heap    postgres    false            �            1259    41739    compra    TABLE       CREATE TABLE public.compra (
    fecha_compra date NOT NULL,
    rating integer,
    monto double precision,
    id_producto integer NOT NULL,
    id integer NOT NULL,
    id_promo integer,
    CONSTRAINT chk_ratingcompra CHECK (((rating >= 0) AND (rating <= 5)))
);
    DROP TABLE public.compra;
       public         heap    postgres    false            �            1259    41580    dispositivo    TABLE     C  CREATE TABLE public.dispositivo (
    id_producto integer NOT NULL,
    modelo character varying(20),
    generacion character varying(20),
    version_ios character varying(8),
    capacidad double precision,
    CONSTRAINT dispositivo_version_ios_check CHECK (((version_ios)::text ~ '^[0-9]+\.[0-9]+\.[0-9]+$'::text))
);
    DROP TABLE public.dispositivo;
       public         heap    postgres    false            �            1259    41579    dispositivo_id_producto_seq    SEQUENCE     �   CREATE SEQUENCE public.dispositivo_id_producto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.dispositivo_id_producto_seq;
       public          postgres    false    218            ^           0    0    dispositivo_id_producto_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.dispositivo_id_producto_seq OWNED BY public.dispositivo.id_producto;
          public          postgres    false    217            �            1259    41681    dispositivos_comp    TABLE     n   CREATE TABLE public.dispositivos_comp (
    id_producto integer NOT NULL,
    dispositivo integer NOT NULL
);
 %   DROP TABLE public.dispositivos_comp;
       public         heap    postgres    false            �            1259    41713    paises    TABLE     g   CREATE TABLE public.paises (
    id_promo integer NOT NULL,
    pais character varying(50) NOT NULL
);
    DROP TABLE public.paises;
       public         heap    postgres    false            �            1259    41712    paises_id_promo_seq    SEQUENCE     �   CREATE SEQUENCE public.paises_id_promo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.paises_id_promo_seq;
       public          postgres    false    235            _           0    0    paises_id_promo_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.paises_id_promo_seq OWNED BY public.paises.id_promo;
          public          postgres    false    234            �            1259    41572    producto    TABLE     �   CREATE TABLE public.producto (
    id_producto integer NOT NULL,
    costo double precision,
    puntuacion integer,
    CONSTRAINT chk_costoproducto CHECK ((costo > (0)::double precision))
);
    DROP TABLE public.producto;
       public         heap    postgres    false            �            1259    41571    producto_id_producto_seq    SEQUENCE     �   CREATE SEQUENCE public.producto_id_producto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.producto_id_producto_seq;
       public          postgres    false    216            `           0    0    producto_id_producto_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.producto_id_producto_seq OWNED BY public.producto.id_producto;
          public          postgres    false    215            �            1259    41704 	   promocion    TABLE     7  CREATE TABLE public.promocion (
    id_promo integer NOT NULL,
    descuento integer,
    duracion integer,
    fecha_fin date,
    fecha_inicio date,
    CONSTRAINT chk_descuentopromocion CHECK (((descuento > 0) AND (descuento <= 100))),
    CONSTRAINT chk_fechapromocion CHECK ((fecha_fin > fecha_inicio))
);
    DROP TABLE public.promocion;
       public         heap    postgres    false            �            1259    41703    promocion_id_promo_seq    SEQUENCE     �   CREATE SEQUENCE public.promocion_id_promo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.promocion_id_promo_seq;
       public          postgres    false    233            a           0    0    promocion_id_promo_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.promocion_id_promo_seq OWNED BY public.promocion.id_promo;
          public          postgres    false    232            �            1259    41724    promousuario    TABLE     ]   CREATE TABLE public.promousuario (
    id_promo integer NOT NULL,
    id integer NOT NULL
);
     DROP TABLE public.promousuario;
       public         heap    postgres    false            �            1259    41598 	   proveedor    TABLE     �  CREATE TABLE public.proveedor (
    id integer NOT NULL,
    correo character varying(50),
    av_proveedor character varying(50),
    nombre_proveedor character varying(50),
    apellido_proveedor character varying(50),
    fecha_afiliacion date,
    esdesarrollador boolean,
    esempresa boolean,
    ciudad_proveedor character varying(50),
    CONSTRAINT chk_esdesarrollador_esempresa CHECK (((esdesarrollador AND (NOT esempresa)) OR (esempresa AND (NOT esdesarrollador))))
);
    DROP TABLE public.proveedor;
       public         heap    postgres    false            �            1259    41597    proveedor_id_seq    SEQUENCE     �   CREATE SEQUENCE public.proveedor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.proveedor_id_seq;
       public          postgres    false    221            b           0    0    proveedor_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.proveedor_id_seq OWNED BY public.proveedor.id;
          public          postgres    false    220            �            1259    41697    usuario    TABLE       CREATE TABLE public.usuario (
    id integer NOT NULL,
    correo character varying(50),
    cod_vvt integer,
    fecha_venc date,
    num_tdc integer,
    nombre character varying(50),
    apellido character varying(50),
    pais_usuario character varying(20)
);
    DROP TABLE public.usuario;
       public         heap    postgres    false            �            1259    41696    usuario_id_seq    SEQUENCE     �   CREATE SEQUENCE public.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.usuario_id_seq;
       public          postgres    false    231            c           0    0    usuario_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.usuario_id_seq OWNED BY public.usuario.id;
          public          postgres    false    230            j           2604    41617    aplicacion id_producto    DEFAULT     �   ALTER TABLE ONLY public.aplicacion ALTER COLUMN id_producto SET DEFAULT nextval('public.aplicacion_id_producto_seq'::regclass);
 E   ALTER TABLE public.aplicacion ALTER COLUMN id_producto DROP DEFAULT;
       public          postgres    false    222    223    223            k           2604    41649    artista id_artista    DEFAULT     x   ALTER TABLE ONLY public.artista ALTER COLUMN id_artista SET DEFAULT nextval('public.artista_id_artista_seq'::regclass);
 A   ALTER TABLE public.artista ALTER COLUMN id_artista DROP DEFAULT;
       public          postgres    false    225    226    226            l           2604    41665    cancion id_producto    DEFAULT     z   ALTER TABLE ONLY public.cancion ALTER COLUMN id_producto SET DEFAULT nextval('public.cancion_id_producto_seq'::regclass);
 B   ALTER TABLE public.cancion ALTER COLUMN id_producto DROP DEFAULT;
       public          postgres    false    227    228    228            h           2604    41583    dispositivo id_producto    DEFAULT     �   ALTER TABLE ONLY public.dispositivo ALTER COLUMN id_producto SET DEFAULT nextval('public.dispositivo_id_producto_seq'::regclass);
 F   ALTER TABLE public.dispositivo ALTER COLUMN id_producto DROP DEFAULT;
       public          postgres    false    217    218    218            o           2604    41716    paises id_promo    DEFAULT     r   ALTER TABLE ONLY public.paises ALTER COLUMN id_promo SET DEFAULT nextval('public.paises_id_promo_seq'::regclass);
 >   ALTER TABLE public.paises ALTER COLUMN id_promo DROP DEFAULT;
       public          postgres    false    234    235    235            g           2604    41575    producto id_producto    DEFAULT     |   ALTER TABLE ONLY public.producto ALTER COLUMN id_producto SET DEFAULT nextval('public.producto_id_producto_seq'::regclass);
 C   ALTER TABLE public.producto ALTER COLUMN id_producto DROP DEFAULT;
       public          postgres    false    215    216    216            n           2604    41707    promocion id_promo    DEFAULT     x   ALTER TABLE ONLY public.promocion ALTER COLUMN id_promo SET DEFAULT nextval('public.promocion_id_promo_seq'::regclass);
 A   ALTER TABLE public.promocion ALTER COLUMN id_promo DROP DEFAULT;
       public          postgres    false    232    233    233            i           2604    41601    proveedor id    DEFAULT     l   ALTER TABLE ONLY public.proveedor ALTER COLUMN id SET DEFAULT nextval('public.proveedor_id_seq'::regclass);
 ;   ALTER TABLE public.proveedor ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    220    221    221            m           2604    41700 
   usuario id    DEFAULT     h   ALTER TABLE ONLY public.usuario ALTER COLUMN id SET DEFAULT nextval('public.usuario_id_seq'::regclass);
 9   ALTER TABLE public.usuario ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    231    230    231            F          0    41614 
   aplicacion 
   TABLE DATA           v   COPY public.aplicacion (id_producto, tamano_mb, version, nombre, descripcion, version_ios, semantica, id) FROM stdin;
    public          postgres    false    223   ��       I          0    41646    artista 
   TABLE DATA           ]   COPY public.artista (id_artista, nom_artistico, fecha_inicio, fecha_fin, nombre) FROM stdin;
    public          postgres    false    226   >�       K          0    41662    cancion 
   TABLE DATA           ~   COPY public.cancion (id_producto, und_vendidas, nom_cancion, fecha_lanz, duracion, nom_disco, genero, id_artista) FROM stdin;
    public          postgres    false    228   ٶ       G          0    41635    casadisquera 
   TABLE DATA           F   COPY public.casadisquera (nombre, av_casad, ciudad_casad) FROM stdin;
    public          postgres    false    224   ��       B          0    41592    ciudad 
   TABLE DATA           0   COPY public.ciudad (ciudad, estado) FROM stdin;
    public          postgres    false    219   �       T          0    41739    compra 
   TABLE DATA           X   COPY public.compra (fecha_compra, rating, monto, id_producto, id, id_promo) FROM stdin;
    public          postgres    false    237   ��       A          0    41580    dispositivo 
   TABLE DATA           ^   COPY public.dispositivo (id_producto, modelo, generacion, version_ios, capacidad) FROM stdin;
    public          postgres    false    218   ��       L          0    41681    dispositivos_comp 
   TABLE DATA           E   COPY public.dispositivos_comp (id_producto, dispositivo) FROM stdin;
    public          postgres    false    229   ��       R          0    41713    paises 
   TABLE DATA           0   COPY public.paises (id_promo, pais) FROM stdin;
    public          postgres    false    235   ��       ?          0    41572    producto 
   TABLE DATA           B   COPY public.producto (id_producto, costo, puntuacion) FROM stdin;
    public          postgres    false    216   ��       P          0    41704 	   promocion 
   TABLE DATA           [   COPY public.promocion (id_promo, descuento, duracion, fecha_fin, fecha_inicio) FROM stdin;
    public          postgres    false    233   �       S          0    41724    promousuario 
   TABLE DATA           4   COPY public.promousuario (id_promo, id) FROM stdin;
    public          postgres    false    236   ��       D          0    41598 	   proveedor 
   TABLE DATA           �   COPY public.proveedor (id, correo, av_proveedor, nombre_proveedor, apellido_proveedor, fecha_afiliacion, esdesarrollador, esempresa, ciudad_proveedor) FROM stdin;
    public          postgres    false    221   =�       N          0    41697    usuario 
   TABLE DATA           k   COPY public.usuario (id, correo, cod_vvt, fecha_venc, num_tdc, nombre, apellido, pais_usuario) FROM stdin;
    public          postgres    false    231   "�       d           0    0    aplicacion_id_producto_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.aplicacion_id_producto_seq', 1, false);
          public          postgres    false    222            e           0    0    artista_id_artista_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.artista_id_artista_seq', 1, false);
          public          postgres    false    225            f           0    0    cancion_id_producto_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.cancion_id_producto_seq', 1, false);
          public          postgres    false    227            g           0    0    dispositivo_id_producto_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.dispositivo_id_producto_seq', 1, false);
          public          postgres    false    217            h           0    0    paises_id_promo_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.paises_id_promo_seq', 1, false);
          public          postgres    false    234            i           0    0    producto_id_producto_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.producto_id_producto_seq', 1, false);
          public          postgres    false    215            j           0    0    promocion_id_promo_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.promocion_id_promo_seq', 1, false);
          public          postgres    false    232            k           0    0    proveedor_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.proveedor_id_seq', 1, false);
          public          postgres    false    220            l           0    0    usuario_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.usuario_id_seq', 1, false);
          public          postgres    false    230            �           2606    41651    artista artista_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.artista
    ADD CONSTRAINT artista_pkey PRIMARY KEY (id_artista);
 >   ALTER TABLE ONLY public.artista DROP CONSTRAINT artista_pkey;
       public            postgres    false    226            �           2606    41639    casadisquera casadisquera_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.casadisquera
    ADD CONSTRAINT casadisquera_pkey PRIMARY KEY (nombre);
 H   ALTER TABLE ONLY public.casadisquera DROP CONSTRAINT casadisquera_pkey;
       public            postgres    false    224                       2606    41596    ciudad ciudad_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.ciudad
    ADD CONSTRAINT ciudad_pkey PRIMARY KEY (ciudad);
 <   ALTER TABLE ONLY public.ciudad DROP CONSTRAINT ciudad_pkey;
       public            postgres    false    219            �           2606    41624    aplicacion pk_aplicacion 
   CONSTRAINT     _   ALTER TABLE ONLY public.aplicacion
    ADD CONSTRAINT pk_aplicacion PRIMARY KEY (id_producto);
 B   ALTER TABLE ONLY public.aplicacion DROP CONSTRAINT pk_aplicacion;
       public            postgres    false    223            �           2606    41670    cancion pk_cancion 
   CONSTRAINT     Y   ALTER TABLE ONLY public.cancion
    ADD CONSTRAINT pk_cancion PRIMARY KEY (id_producto);
 <   ALTER TABLE ONLY public.cancion DROP CONSTRAINT pk_cancion;
       public            postgres    false    228            �           2606    41744    compra pk_compra 
   CONSTRAINT     i   ALTER TABLE ONLY public.compra
    ADD CONSTRAINT pk_compra PRIMARY KEY (fecha_compra, id_producto, id);
 :   ALTER TABLE ONLY public.compra DROP CONSTRAINT pk_compra;
       public            postgres    false    237    237    237            }           2606    41586    dispositivo pk_dispositivo 
   CONSTRAINT     a   ALTER TABLE ONLY public.dispositivo
    ADD CONSTRAINT pk_dispositivo PRIMARY KEY (id_producto);
 D   ALTER TABLE ONLY public.dispositivo DROP CONSTRAINT pk_dispositivo;
       public            postgres    false    218            �           2606    41685 &   dispositivos_comp pk_dispositivos_comp 
   CONSTRAINT     z   ALTER TABLE ONLY public.dispositivos_comp
    ADD CONSTRAINT pk_dispositivos_comp PRIMARY KEY (id_producto, dispositivo);
 P   ALTER TABLE ONLY public.dispositivos_comp DROP CONSTRAINT pk_dispositivos_comp;
       public            postgres    false    229    229            �           2606    41718    paises pk_paises 
   CONSTRAINT     Z   ALTER TABLE ONLY public.paises
    ADD CONSTRAINT pk_paises PRIMARY KEY (id_promo, pais);
 :   ALTER TABLE ONLY public.paises DROP CONSTRAINT pk_paises;
       public            postgres    false    235    235            �           2606    41728    promousuario pk_promousuario 
   CONSTRAINT     d   ALTER TABLE ONLY public.promousuario
    ADD CONSTRAINT pk_promousuario PRIMARY KEY (id_promo, id);
 F   ALTER TABLE ONLY public.promousuario DROP CONSTRAINT pk_promousuario;
       public            postgres    false    236    236            {           2606    41578    producto producto_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id_producto);
 @   ALTER TABLE ONLY public.producto DROP CONSTRAINT producto_pkey;
       public            postgres    false    216            �           2606    41711    promocion promocion_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.promocion
    ADD CONSTRAINT promocion_pkey PRIMARY KEY (id_promo);
 B   ALTER TABLE ONLY public.promocion DROP CONSTRAINT promocion_pkey;
       public            postgres    false    233            �           2606    41604    proveedor proveedor_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.proveedor DROP CONSTRAINT proveedor_pkey;
       public            postgres    false    221            �           2606    41702    usuario usuario_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.usuario DROP CONSTRAINT usuario_pkey;
       public            postgres    false    231            �           2620    41767    compra check_dispositivo    TRIGGER     }   CREATE TRIGGER check_dispositivo BEFORE INSERT ON public.compra FOR EACH ROW EXECUTE FUNCTION public.fn_check_dispositivo();
 1   DROP TRIGGER check_dispositivo ON public.compra;
       public          postgres    false    237    241            �           2620    41769    compra check_dispositivo_true    TRIGGER     �   CREATE TRIGGER check_dispositivo_true BEFORE INSERT ON public.compra FOR EACH ROW EXECUTE FUNCTION public.fn_check_dispositivo_true();
 6   DROP TRIGGER check_dispositivo_true ON public.compra;
       public          postgres    false    237    242            �           2620    41765    compra check_pais    TRIGGER     o   CREATE TRIGGER check_pais BEFORE INSERT ON public.compra FOR EACH ROW EXECUTE FUNCTION public.fn_check_pais();
 *   DROP TRIGGER check_pais ON public.compra;
       public          postgres    false    240    237            �           2620    41761    compra fn_check_descuento    TRIGGER     �   CREATE TRIGGER fn_check_descuento AFTER INSERT ON public.compra FOR EACH ROW EXECUTE FUNCTION public.trf_insert_promo_incentivo();
 2   DROP TRIGGER fn_check_descuento ON public.compra;
       public          postgres    false    237    238            �           2620    41775    promocion fn_check_duracion    TRIGGER     }   CREATE TRIGGER fn_check_duracion BEFORE INSERT ON public.promocion FOR EACH ROW EXECUTE FUNCTION public.fn_check_duracion();
 4   DROP TRIGGER fn_check_duracion ON public.promocion;
       public          postgres    false    256    233            �           2620    41771    compra fn_check_monto    TRIGGER     t   CREATE TRIGGER fn_check_monto BEFORE INSERT ON public.compra FOR EACH ROW EXECUTE FUNCTION public.fn_check_monto();
 .   DROP TRIGGER fn_check_monto ON public.compra;
       public          postgres    false    237    243            �           2620    41773    compra fn_check_monto_descuento    TRIGGER     �   CREATE TRIGGER fn_check_monto_descuento AFTER INSERT ON public.compra FOR EACH ROW EXECUTE FUNCTION public.fn_check_monto_descuento();
 8   DROP TRIGGER fn_check_monto_descuento ON public.compra;
       public          postgres    false    237    255            �           2620    41763    compra fn_check_puntuacion    TRIGGER     }   CREATE TRIGGER fn_check_puntuacion AFTER INSERT ON public.compra FOR EACH ROW EXECUTE FUNCTION public.fn_check_puntuacion();
 3   DROP TRIGGER fn_check_puntuacion ON public.compra;
       public          postgres    false    239    237            �           2620    41777    compra fn_check_und_vendidas    TRIGGER     �   CREATE TRIGGER fn_check_und_vendidas AFTER INSERT ON public.compra FOR EACH ROW EXECUTE FUNCTION public.fn_check_und_vendidas();
 5   DROP TRIGGER fn_check_und_vendidas ON public.compra;
       public          postgres    false    257    237            �           2606    41630 "   aplicacion fk_aplicacion_proveedor    FK CONSTRAINT     �   ALTER TABLE ONLY public.aplicacion
    ADD CONSTRAINT fk_aplicacion_proveedor FOREIGN KEY (id) REFERENCES public.proveedor(id) ON UPDATE CASCADE ON DELETE SET NULL;
 L   ALTER TABLE ONLY public.aplicacion DROP CONSTRAINT fk_aplicacion_proveedor;
       public          postgres    false    221    4737    223            �           2606    41676    cancion fk_artista_cancion    FK CONSTRAINT     �   ALTER TABLE ONLY public.cancion
    ADD CONSTRAINT fk_artista_cancion FOREIGN KEY (id_artista) REFERENCES public.artista(id_artista) ON UPDATE CASCADE ON DELETE SET NULL;
 D   ALTER TABLE ONLY public.cancion DROP CONSTRAINT fk_artista_cancion;
       public          postgres    false    228    226    4743            �           2606    41652    artista fk_artista_disquera    FK CONSTRAINT     �   ALTER TABLE ONLY public.artista
    ADD CONSTRAINT fk_artista_disquera FOREIGN KEY (nombre) REFERENCES public.casadisquera(nombre) ON UPDATE CASCADE ON DELETE SET NULL;
 E   ALTER TABLE ONLY public.artista DROP CONSTRAINT fk_artista_disquera;
       public          postgres    false    224    4741    226            �           2606    41640    casadisquera fk_ciudad_casad    FK CONSTRAINT     �   ALTER TABLE ONLY public.casadisquera
    ADD CONSTRAINT fk_ciudad_casad FOREIGN KEY (ciudad_casad) REFERENCES public.ciudad(ciudad) ON UPDATE CASCADE ON DELETE SET NULL;
 F   ALTER TABLE ONLY public.casadisquera DROP CONSTRAINT fk_ciudad_casad;
       public          postgres    false    4735    219    224            �           2606    41605    proveedor fk_ciudad_proveedor    FK CONSTRAINT     �   ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT fk_ciudad_proveedor FOREIGN KEY (ciudad_proveedor) REFERENCES public.ciudad(ciudad) ON UPDATE CASCADE ON DELETE SET NULL;
 G   ALTER TABLE ONLY public.proveedor DROP CONSTRAINT fk_ciudad_proveedor;
       public          postgres    false    219    4735    221            �           2606    41745    compra fk_compra_producto    FK CONSTRAINT     �   ALTER TABLE ONLY public.compra
    ADD CONSTRAINT fk_compra_producto FOREIGN KEY (id_producto) REFERENCES public.producto(id_producto) ON UPDATE CASCADE ON DELETE SET NULL;
 C   ALTER TABLE ONLY public.compra DROP CONSTRAINT fk_compra_producto;
       public          postgres    false    4731    237    216            �           2606    41755    compra fk_compra_promoción    FK CONSTRAINT     �   ALTER TABLE ONLY public.compra
    ADD CONSTRAINT "fk_compra_promoción" FOREIGN KEY (id_promo) REFERENCES public.promocion(id_promo) ON UPDATE CASCADE ON DELETE SET NULL;
 G   ALTER TABLE ONLY public.compra DROP CONSTRAINT "fk_compra_promoción";
       public          postgres    false    4751    233    237            �           2606    41750    compra fk_compra_usuario    FK CONSTRAINT     �   ALTER TABLE ONLY public.compra
    ADD CONSTRAINT fk_compra_usuario FOREIGN KEY (id) REFERENCES public.usuario(id) ON UPDATE CASCADE ON DELETE SET NULL;
 B   ALTER TABLE ONLY public.compra DROP CONSTRAINT fk_compra_usuario;
       public          postgres    false    231    237    4749            �           2606    41686 1   dispositivos_comp fk_dispositivos_comp_aplicacion    FK CONSTRAINT     �   ALTER TABLE ONLY public.dispositivos_comp
    ADD CONSTRAINT fk_dispositivos_comp_aplicacion FOREIGN KEY (id_producto) REFERENCES public.aplicacion(id_producto) ON UPDATE CASCADE ON DELETE SET NULL;
 [   ALTER TABLE ONLY public.dispositivos_comp DROP CONSTRAINT fk_dispositivos_comp_aplicacion;
       public          postgres    false    229    223    4739            �           2606    41691 2   dispositivos_comp fk_dispositivos_comp_dispositivo    FK CONSTRAINT     �   ALTER TABLE ONLY public.dispositivos_comp
    ADD CONSTRAINT fk_dispositivos_comp_dispositivo FOREIGN KEY (dispositivo) REFERENCES public.dispositivo(id_producto) ON UPDATE CASCADE ON DELETE SET NULL;
 \   ALTER TABLE ONLY public.dispositivos_comp DROP CONSTRAINT fk_dispositivos_comp_dispositivo;
       public          postgres    false    218    4733    229            �           2606    41719    paises fk_paises    FK CONSTRAINT     �   ALTER TABLE ONLY public.paises
    ADD CONSTRAINT fk_paises FOREIGN KEY (id_promo) REFERENCES public.promocion(id_promo) ON UPDATE CASCADE ON DELETE SET NULL;
 :   ALTER TABLE ONLY public.paises DROP CONSTRAINT fk_paises;
       public          postgres    false    235    233    4751            �           2606    41625 !   aplicacion fk_producto_aplicacion    FK CONSTRAINT     �   ALTER TABLE ONLY public.aplicacion
    ADD CONSTRAINT fk_producto_aplicacion FOREIGN KEY (id_producto) REFERENCES public.producto(id_producto) ON UPDATE CASCADE ON DELETE SET NULL;
 K   ALTER TABLE ONLY public.aplicacion DROP CONSTRAINT fk_producto_aplicacion;
       public          postgres    false    4731    223    216            �           2606    41587    dispositivo fk_producto_cancion    FK CONSTRAINT     �   ALTER TABLE ONLY public.dispositivo
    ADD CONSTRAINT fk_producto_cancion FOREIGN KEY (id_producto) REFERENCES public.producto(id_producto) ON UPDATE CASCADE ON DELETE SET NULL;
 I   ALTER TABLE ONLY public.dispositivo DROP CONSTRAINT fk_producto_cancion;
       public          postgres    false    218    216    4731            �           2606    41671    cancion fk_producto_cancion    FK CONSTRAINT     �   ALTER TABLE ONLY public.cancion
    ADD CONSTRAINT fk_producto_cancion FOREIGN KEY (id_producto) REFERENCES public.producto(id_producto) ON UPDATE CASCADE ON DELETE SET NULL;
 E   ALTER TABLE ONLY public.cancion DROP CONSTRAINT fk_producto_cancion;
       public          postgres    false    228    216    4731            �           2606    41729 &   promousuario fk_promousuario_promocion    FK CONSTRAINT     �   ALTER TABLE ONLY public.promousuario
    ADD CONSTRAINT fk_promousuario_promocion FOREIGN KEY (id_promo) REFERENCES public.promocion(id_promo) ON UPDATE CASCADE ON DELETE SET NULL;
 P   ALTER TABLE ONLY public.promousuario DROP CONSTRAINT fk_promousuario_promocion;
       public          postgres    false    4751    233    236            �           2606    41734 $   promousuario fk_promousuario_usuario    FK CONSTRAINT     �   ALTER TABLE ONLY public.promousuario
    ADD CONSTRAINT fk_promousuario_usuario FOREIGN KEY (id) REFERENCES public.usuario(id) ON UPDATE CASCADE ON DELETE SET NULL;
 N   ALTER TABLE ONLY public.promousuario DROP CONSTRAINT fk_promousuario_usuario;
       public          postgres    false    4749    236    231            F   m  x��YM��=E�&A.���K@�6v약�dri����������W�@�=����'�%y�����N���3���W�^g�lz���F�)�ˮW���ֹ&����it�U۩<�ڵ-t�D�q�-�Q��S�U	�*���YV�J��Q��K[������ë�z�}��j{��F+S)>���
g���Xb�ښ;���u�vAY�(SLХ�Z��Y����j���wrx�o������R=Rou�#�L�M]����A�xe~�M��R~ȗ9,�|Pc�+�W�-q�J��5nڨ��q��{��j�O;�����{\g9�U�Y���o��:zv��n���|����W�i�\�0���8P��U�X,{93�&G��tt<��,^��ma|�M�I6���x2:��'�+�4����Tt�mg���-��Q��W�������p[�p���71��#���`mO�!�y
?��Ah��E��Z�L@�-c�\R��34�amm�]-Թ�W�:<��ߵ]�*���W�~e�Z[;�]n�T�©!tu�����i���)��߫�¶x?Tug$t�^���KA����*^�����K�GS	��`v��Ս�,0
H#��1�	��T��Gi+�ja}���6p��4)������X��W���³������C�n?+z�4O����xM��h0;�N���t��+��^��k��:��v���!K�q!�Q���$���9co��	�F�����ߘ���H]i5�k|Gi���`}�n�C!�6p�����ւQ"� 9p�S�{Y�����/�M�i.��`M�������zmr[����jL�/d�D#=�_�Ҁy�), 7�<ZIc�#;ZOl�v�O�$l��
�}���ސ�@a��Y����i$��Q�����Su`Ɔ1�Ց,�	���s�=<� �.a�����"�LM��oB�
QC,	L���4��H]��sDh�Oͽ	c:dgvq讷߿�����!�箳��m�h��cNJ�U�}���Aȁ��5��[7�������B��nVzt�s���2��~�ػ��-����:U�Ø�}̱)�Xo�iS���+y|����H��£���x0;�N��g#��dߒ��(4��d�F�}��5.���`K�)�J�v�=�ڰ�U�k��ѣ�Z��X0�``�z�V\� ����!��#���66������+�!��$��=��x�1<�r~IY@ޥ���<_8�[�l=�뢜��}Ś��6���ˢK	��f'��^dFO�y��@��ڪ�w^��,�����������jg,1�n�Jq��z"ӿCdo�R3u�1�4��Nh�x��~����L����C,t	H�L��ڈp�k�e��D��s�|7/��FA��˴;���[�X��$�N�<
�ӕ�k�{�w$v:��f�GB�����+؅����1)1$�P�X`��v�1��Fn�Rd�`X��ҍp:���d3���WU�nӔ9�LA�j�/(����c�E.���
&ȅ����+�"+��v&��<�nM�c�(-����M@�f<�y	�׺��Z�G�Eج��GB�r!���n��,��"�%���v�S����lrz�xM	��'ݶ׺�v�>�:�-@�� *�	����&
D��7��& �����ϑ�	��՛.$c��a)6~֔��H"�r҄��f/rG�jl��R����Z���p��T���P!����Nh�<�	�;�f��dB�7(��ׅ�k������o���6Ev"?���/6�R�V�b^�@[jI�Ok�㟠"��~8�A�cnDWӅ�(�WR��"�;�d��젤��=�����g��C�'1����B�~�ͣ؛#��V�D�*%�|������Ĭ㦒��J�}�tI�P��F��^��Ҽi�y"+�k_ֆOH��+�������j�3���L)��$795GIBi����~1��۹�
�I�D�HMz{>��C۞,Ǥ��Z�����=�w����R�	Z[��#5��mv=��橓��k��0�e���ٻ�)n-\]��i-4��tK�=�K� ]U!iÐMΒd��,&���8�N�[�켃(�H�y�b�RG\؂Fj#@��2,�{��4���7 ��e�(��i:v%�x�� Rh!���|�N/u0f��В'�Q%�-�aD�S�8z3~r1�����=҂��<k6����.��J�4ٚ��L���H�#�:����5�y��B��1_�&����̲�d��L i�%��R�R�|%�ϔ_G��H� P�0)�����H[���V|���pjAg�K�#bu��h�llP��c�L��a�-�D
�b��.�:�@j�0/�����w�w48?0ϲ��'�
�Ι��˫8΄X�d׽�J2-o�Bb�\�@�B�Ü�G�%��M�&�$24*���� UP��X�U��G�.A���'3��kp�a/�S�S� ��pcw;6Ϯ�m�A����n�P����r���Nc�,L5�������H�2gو��9߂�)��u�T��ש)��)ˣ,�CghM/ㄡ��2�D�2�yt�T�Z9JY��F�^���G����=zP/J�P�L����M0�&4)``o��):�O��)���N˿��ɮX��X�#��]�I�&d~}���40aG�2j�v��v	���W��cc�+�(kî/D�ⅸ�L�Ɩ���݃v��°�8#�d^�M(f8�K��xp�b'����z��L�cЦ?��|)ѻQ1C���]ya�(��i)���?��K!�+l4��Y��G
o��-|�J�W(F�h�ئ>!qJ����fx49�h�m��3h�X=}���P�p������oՏ��~���v���7�ߩ��e��3�[��Y���H7���s<Q�ֱS�5&�Cҳc	|
XWy���v^�S[��ҮDGyq�.�+�
a���K�f�� 夾�m���r:c�d��ؙY�;���h����Jyn.�ș�f�|2�@4OgSQ�@�T��X�u��i5*l�F�5�w�0X@I��+*��x[҄Lc�TN��a����z���蒳�a/�9g�R�{d�nq"Ҍ n�z9�J��T`.�/�8�����T�%�z9#����,��·��(��q�b"wi��}%�F�"�_N��t�s����[������h�I�ƧO�S��,;=���/��ȪWh瞫^�2O=�����G�Xpd���9�_|�t���R�UVZ�oPfC��2:� F��F?�!��
1)�╎��?i�dV+�3�bdH���ޙT�d��!gp�,��;(�fټ�Wڵj�\�mX��g}1��\I
�ݴ�����2R~��d減n��&�I�Ek���+(�8o%�h���9��H6p?�HUHWRQ��I����6gR�	E��FC����{c�L#�ul�1[���i:9M���X�(a|0П��st�2���kU�2h��Ᾰ��y�}�c��R)���C�v?��	�0�:܉��F9D����p�lΞ�MWn?�[V��)֐�sѮ#��E�#�7N��
!�E�D|T1�v��<�A�_6T�#�Ԥ��K����l2�t�(D�v=*T����MgR��v�<�m4�����      I   �  x�uT�n�@|>��~��Àͣc����Xv�(U^Vp���:�����ؤ};��ٙ�[�Ie<ie� q칞�z�������b�+��(�N��f�㳝���i��PZ+��ǣ�5V�/����{��U�Hۀ�JY5΄�JUɒ��'��X����Z����7�#1�(-��Gy2|��*uB����	�@���O�[��r��%�(�/-䦪�F���l)�S6Ϥ�D{�{>�&v�`�Şo��ڴQH���\Cş@�%ZN]?�ҍ�Pjn>���I�J]��������v�($���hI����J�S��񜌫�(-;��lKv��%-XP�����-�:�e���*��/&H� 5���P����;�C��h�����a�"`�ic��M�6�L�5�K,���2SU�{<�^.�V�[�;����?�����Mٍ�L�ʯ�Q~6��=n���R�!8e ;|BKř��dE�/hQ���4JD��I�3Α��m�Mz�Ň�;T2>C_�}ȇ/M��D	ןw3�_��^���3�U�!��g�7��@ZP2���?%�tt���������kK���!"������Z-�_v�Gl[���� �Wݧl�4�|�q��9C�"2{	��U(l⊕�u�E�o�����^�      K   �  x��X�n��>�Oѧ`���?�87��=�lC�Y#�^�R��b��W9�k�S^$o�O�������l0쪮�ꫯ��?__t#n��I̋V�A�lMGqD��(�O0���lT)�Z��!X��S��c2?�e�V�Y�#�$[�?�����NWZ|���l����|ȑ��G�1����9?�����cpk�JI�nU��B�[i^tU�@�yN�Ȉ�%Й*̃�J�[���P��b]�W��G0�2�Z7jkڽ�U��7K�l��'q�7��M���H1�@��nԫ:���U� ^9IGU����n�b�GQ�ap�����S����a4�ζ�Xjo��)���#�O{S���]��ܐ�r�P��e[��^�����'g�u#����Z����ea�p��VFU���Q�Zɣŧ[��y�v���][n5����%��-�0�4ovby���G�6L"�k�L̵�k[jqe����m+O.�e���6	�oVH� ����]4�X��0�lĝ��m�i��a�Pܔj+�͌�}���	�{Sf��ci�n�ʌ��S�j�(��ʾ���x�Ĉ��{˭}a[�S&��W � ��nv}-&#� M���z���4����+�3��S�7Me��ș#��K-��e�e�(��9�T�����"]���n���ӣ츸����)��=���������+��GSF�����OB(�{�t�+�z_��=�N�����:�0uxkq��>��X��*u��ސ�{i)Z�Z�}�5�&?6�-fj�Q�dp�E�y*��ԧ��e©�]���.�$�3w#.2y��OM\���j��J�=�a:����ʚ�%��.�4�8����pو��� ~k��6�a"�c���sWz;��'�3��k�� >�/(2w���[BˎR���幛7�
��Jz�T7;
q|*.�`���<�\��B�F<��0%��f�F�%~2գ){c.
��Vup�|C�t��':c֚/�Х�cu}�8�h�υ����83����� b��x�P����.�l�ۯ�kU�87����'�Yq��m�!t�.��%��p��0gf��vE�ʸ[#����z��a>�����(��	�'��R�Y�>|����ڂlϺ�ya������4W{Ig�"�3ӷ��z`�Z�svX|��3�׬��'���j��{q�w������$D�ZV7�e!s&}�&�S�΃mE�{��[�kIL.�w�ı�������"��5��2���u�W�yҍ�&�����[A�D}V�`B��>����d��ʔuC*!ֺ(��]0]��s�6���ݔ 8��ͷ� �V1e��HE��C������Lϭ��/m��K׵��8���0?mu�=�O�'Y y�+�iK�4~���W�<Lc�������Peډ��;�rļc�4e]Z���@�*����B�bg��ݫ��FG!_��v�*�[~<Jx�v��-����X����-i���qm��7a֩���kP�I��[�$�*��:Ut�vX���%�'���+�G�H�=k%����K�o�F�F���#�{��C�;�����_)qYJ̡����2�}��I�.�B��;Q"�sV,'0L�ZCi;(L���$�c�� _�*��tΩ�xDY^�e��t/}�4Lpti�����㔋�T֯=jT�[�E���̰���1LVQ"�)Y�Z?����v#�߸c�n����k��w^o_d�:xo5w_��	�z[@7/ ��2^)���������iU���TYP��ǧ0,I���m>�t���5u��B�Gl枡�G��ssjL�sf7��XAV�b�u~��{��Lh%��jݖ�����V✲�n?��c�U͠�:X�pN�T�k�*Vm��Jd�_�V���ܛ$9�7����N��"b��=��J�0ݪ�_�st2��ؙ�M�	~'�����������n݇��0����      G   \  x�m��j1�ϛ��=��.�RVXTK/cv�ٌN��6=��C����bm���3�7���z=�,ou�}��<�@Y�^�qѫ���J��&;߇S���
0�U	���hX�c`�� B�KZ��Y�I�5���~,М&	�lN?��-�і��$]�. 9qgڒ��z��lr��CK4�A"�(��j|�I���%�]$OV��ux80|?���!��9z���7�Q?�C�`�%�����v�&Z�C�G	�%�^y�(����.������:O�h6��1�����
����ݽZ<�a��y��f6͟j��+�k!{�J���^J�oŗѯ      B   �   x�-��m�0E����;�.ڋh E/�B8,ёă�Mf�^���$�����(S�oRj��MG�T�x��-
�qv��)X�*�7zh����G�B��<+�&�E�y�(]�;Y�8C�i4Zs�y�O<Q���sߠ�nD-��/_x+���qU�݈����w��^G^T͙p�Q��7N�.E8.�pu�1��p^�ٌ=5F.��yA�f]g�      T   �  x��VI�1;�q�����w� {S�=q�Z$@��U�<�R���0�I�$�������FF��K�I�+��N���J����P�83=D�9uP$B��I��WX�.m�F���}:`�lL]�{��2�	&rL�A�޿�*d�Pu,�6�<,��||㎲�\��Uyk�����y�W)$[�B�>�3|���N_l�E�ЭM�E���:�p�6�ؼ}��D�4���lڭ��MKx�M-�^:tw�bڗ���rDb�V����T��lVͷ[t��-�Oq|�%���hk�n8����N���I����U���0K;���<�(�[�|�--��!o�L���D�]�AU�a�"u6|nθv�T;w�5�sx�9����
F��ŢdK_G��Bz�1��� 0�N���X��gI9�����Hfw���'y�%_,�z��<R:x=��Ҩ�Q���/=�p@׸����G�"���.+_���'��Zu��A�-�������8`!��n>H�-7Ո��Sł:{d�B).2��f�:?Y�Q�n�H��CD��2�сk�c�x�t�O�R�}�t�Z(h���V�-ᜱ�f�.ɜ��V���{������{�.���Ӌ�%�J{�����ӷ���(��#�2�����icP�gJ�܇O'�VG#���x^��ň��5�M���喇��'�Q��c8w�TpS�� ���
om&��Ї�4��R0��w�j�K���`Js�ث���r[[�K����fi����w��Ls�-yN+y�����sց?udl���3Cw�޵/�ެ�\�3~��8�dIϒ��)���Q3fd�|�s��'�0��ģ=�Iu����W��;�<e�>@�_!�_ ��!��Q>�)�w)僔ǯ��3�D|�k�<�Y�9~��=B�㥸�"��X�=������^���φ���n���N��1      A     x�m�1j�0Ek�:�ь���L���m�HcC��W���e$Yb��2����q|�.����*�e^������/v��iAV5z2G���x*��t�0q�HR���U����P�I_͇jj|���� �n�^��6]�N�w�B �B-��r���*ׁ.���ǚ{>�W�07��o�ߨ���3�)6��t�F������V��w/����T^�~IJV<����o:�V��Ӌ���ߐ0�m� �o6B��E�<H)� �ȯ8      L     x�5��q1ѳ7��;�\�&��%�[+�����Y;��d��W��݂*��*��*��*�U��W��_��~��٤fhCch��14�����:��:��:��:jg�Mv�l`�sp��98����sp��98�����srN��99'�d���6��l`��C0�g�����d�����6�}ӾiߴlZ6-��M˦e�~��S�^i��WZ'�vI��]��'8g��}[gݓ�J��:��{�uO:�����\ N3o3o3O���y���~      R   �   x��;�0��Sp�I��Q��y$V����%�6��!�P�)�f������JL�R��N���C�D9��G�<���A{�Sy6V�"i.>�%����WTB�OV�G���Vw�$VS�|l#�2�����������`��q��_�8h      ?   ]  x�MR۵!��b��K��[��_�uF!�5	!��Ѿ4
�B̀���0

:h2[Oa��nZV(�-�+���LK���0�w@�ZG�;�v�pX��3A�$�l�#�wp��
{�صɋ�[_`->�/�&���|8�%��)�V:�i���U���$�c$�ms�v_�lV5&���Q�c4�G�ƪ���FS+P��86�i�ѓ�����h�AN���ݩ���_���T!�KU��특��1�18��T���L���5�0M�`�d��]&���wY5s�y9�ݫf2�ʾFz�~�:��t��lE�|e�yV�a6w)sqZnn��J7���~��eɈ      P   �  x�uT[�!������ϻ���1�iE�ڪ�p:BH7�AK
E�G�{��	���5C�@5(���FC�@S�r����:N�$[-?j4@K`1�T񬭁ۋ�.��8rB14���"��&�����r��&*�������[�LX���&�'��t�*O8[���2����a"�/�3A׆u���Շ�Σz�m�͍�O����u�Kt��%B�����B��M>]��]�F�\Ly�%]ҺIkSZvpT۷���z�%��ԫ:��#���\yw��ˋ����h�nnЭ��I�Ww��>�j���A,vCZ��u���A�5�-Z}�ُ���P�I��C�8tJ�m��}�`���ba��t�v}��tM�Q��`)9i+k胬���o��7֎!(Yָ� ����} ���=      S   k   x���1�R���e���k.YA�;
<A�ol�	A&� ���!kH]��\Iטּ-ü���}��5�������p����lo!�;H�^d�䊮k���?M��      D   �  x�}��N�@���O�0�H��SD Jڮ��ؗ0t<��O$x�>@U!/�k��,6(B����93<�YQYר�A�5L7dT��):4�A�
h`F/y��I�&�1x��S�X��rx$�����j��Z	\���%�a��lf��Zq4�n�Vd�bKn���*�%��*�����Mk�%Y��1�0d=��g,C���!P��ܳ�ѫ�t|Ml�����߭������{�	ڒ4�� 4���_E�)��B�ќ�!¿⥗轩0͒��3]����y��1��G�iy]�����_I�R���.$��8Kر0y��9�@SS�� ��V�d���b1�h�ǳV�g�
�=ed�R\pʬ���!st�2��krp)�P�|}bO8-�Gg�StF�$*�V�@�)��4�N:
��:!,[eW�6��pe��]��А��E1ĕ�,�d#1�\���~�%٨3OA9U��H���<�x��I۱�X���3�c��;�����)�����z�CHσ��faI�
���|��/��)����J�7�qE�T��p։����*�w�I:I����Z����
u$���y��Қ�á}QEۿ,�Z�\ ;m��(ɋ}O�2놢���#%^rXi�R�Tf/U-Z�[?�K�/��d�}C/�z-�VR�u+��*>zM`-��z0���#\�q�2�V�#�'{���&����'�Ϊ�L�wmL>�;���?	��       N   �  x�eU�r�8<�b@) $���;ޤ�]W�Xb(�(B������|H��c��_���h�L�4$=��ݗ�|>�v�nޭ펤�I	��^	�G�S� �? ��Cg6���}[�+R�3�6��/h�M��Jj��BHE7�����_@�{Ӛ��Ŵ6���ʶϦY��Ө�T�XP�,�A����K�L�����D	�uu����<v%�Ji�b��[�%u�k�$ۺ)#MM_�]o�N�\���u������ţ�f��_��QJeS��ٍ��~AS�Y�K�	S��DA�����|���C�L��2ڗg��kM�YJ�d��d���nN��6�Ք;ӂ*����lj3gQ:#�F����5C�rA�u�]T��~�Mew��E�I�HRi����o,���p�w}՛��C5}�tֹ�0oGa�k�)<�h���tY���FRB�um\������ޜUJd�\�k.�3c�K�����zS����++3�H�Ўf���^�`,�������Ș�ð-��}7���Xt��='H^�����x���pZ_B�ypu�����KT��Y�D웫#��j���<���3;��E3�\�КZ��48�� ���ǶjLW:�t�����3�4�F)��h��������5~��z>�؏;c�x�J��{<ݏ���7�}+�>���4Iu��-C�l�+ۧ�U
mygJM6�����j��Y[�E��Cda;�\|����!_�R�3X
9_�X-8/�:�3x�W
u�d�����H�@řD6��{e�_��,j�_)Ⳮ�N#j�G�ĩ\��<�\u�t�| K��.�i'���tN���U?Z0I�gͤcrCX��~�>1�Mtc�>�H�*�/�"�
��|�p��SaG���J�-|O�(2�r@������6�9���gmӅ��*���4����hPm�e��]4��l
_����c�p%��?�M�Z���<��3(����jd����EQ�?�{x     