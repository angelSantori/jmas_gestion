import 'package:flutter/material.dart';
//import 'package:flutter_svg/flutter_svg.dart';
import 'package:jmas_gestion/general/login_page.dart';
import 'package:jmas_gestion/medios/list_medios.dart';
import 'package:jmas_gestion/ordenServicio/add_orden_servicio.dart';
import 'package:jmas_gestion/ordenServicio/list_orden_servicio.dart';
import 'package:jmas_gestion/service/auth_service.dart';
import 'package:jmas_gestion/tipoProblemas/list_tipo_problema.dart';
import 'package:jmas_gestion/widgets/componentes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String? userName;
  String? userRole;
  String? idUser;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: -250, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final decodeToken = await _authService.decodeToken();
    setState(() {
      userName = decodeToken?['User_Name'];
      userRole =
          decodeToken?['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      idUser = decodeToken?['Id_User'];

      _currentPage = AddOrdenServicio(idUser: idUser, userName: userName);
    });
  }

  Widget _currentPage = Center(
    child: CircularProgressIndicator(
      color: const Color.fromARGB(255, 75, 0, 130),
    ),
  );

  // Método para obtener el Map de rutas
  Map<String, Widget Function()> _getRoutes() {
    return {
      //OT
      'addOrdenServicio':
          () => AddOrdenServicio(idUser: idUser, userName: userName),
      'listOrdenServicio': () => const ListOrdenServicio(),

      //  Problemas
      'listTipoProblema': () => const ListTipoProblema(),

      //  Medios
      'listMedios': () => ListMedios(),
      //Productos
      // 'addProducto': () => const AddProductoPage(),
      // 'listProducto': () => const ListProductoPage(),
      // 'listConteo': () => const ListConteoinicialPage(),

      // //Ajuste Mas
      // 'addAjusteMas':
      //     () => AddAjusteMasPage(idUser: idUser, userName: userName),
      // 'listAjusteMas': () => ListAjusteMasPage(userRole: userRole),

      // //Users
      // 'addUser': () => const AddUserPage(),
      // 'listUser': () => const ListUserPage(),
      // 'adminRole': () => const AdminRolePage(),
      // 'addRole': () => const AddRolePage(),

      // //Entradas
      // 'addEntrada': () => AddEntradaPage(userName: userName, idUser: idUser),
      // 'listEntradas': () => ListEntradaPage(userRole: userRole),
      // 'listCancelados': () => const ListCanceladosPage(),

      // //Proveedores
      // 'listProveedores': () => const ListProveedorPage(),
      // 'addProveedores': () => const AddProveedorPage(),

      // //Salidas
      // 'addSalida': () => AddSalidaPage(userName: userName, idUser: idUser),
      // 'listSalidas': () => ListSalidaPage(userRole: userRole),
      // 'listCanceladosSalida': () => const ListCancelacioensSalidaPage(),

      // //Alamcen
      // 'listAlmacenes': () => const ListAlmacenesPage(),
      // 'addAlmacenes': () => const AddAlmacenPage(),

      // //Juntas
      // 'listJuntas': () => const ListJuntasPage(),
      // 'addJunta': () => const AddJuntaPage(),

      // //Colonias
      // 'listColonias': () => const ListColoniasPage(),
      // 'addColonia': () => const AddColoniasPage(),

      // //Calles
      // 'listCalles': () => const ListCallesPage(),
      // 'addCalle': () => const AddCallesPage(),

      // //Herramientas
      // 'listHerramientas': () => const ListHerramientasPage(),
      // 'addHerramienta': () => const AddHerramientaPage(),

      // //HtaPrestamos
      // 'listHtaPrest': () => const ListHtaprestPage(),
      // 'addHtaPrest': () => AddHtaprestPage(idUser: idUser, userName: userName),

      // //Consulta universal
      // 'ConsultaU': () => const ConsultaUniversalPage(),
      // 'listPDF': () => const PdfListPage(),

      // //X
      //'home': () => const Center(child: Text('Welcome to home Page!')),
      // 'listPadron': () => const ListPadronPage(),
      // 'listCC': () => const ListCcontablesPage(),

      //'mapa': () => const MapaLecturasPage(),
      // 'addAjusteMenos': () => const AddAjusteMenosPage(),
    };
  }

  void _navigateTo(String routeName) {
    final routes = _getRoutes(); // Obtén el Map de rutas
    if (routes.containsKey(routeName)) {
      setState(() {
        _currentPage = routes[routeName]!();
      });
    } else {
      throw ArgumentError('Invalid route name: $routeName');
    }
  }

  void _logOut() {
    showDialog(
      context: context,
      builder: (BuildContext cotext) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                //1. Cerrar el diálogo
                Navigator.of(context).pop();

                //2. Limpiar datos de autenticación
                await _authService.clearAuthData();
                await _authService.deleteToken();

                //3. Navegar al login limpiando toda la pila
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isAdmin = userRole == "Admin";

    return Scaffold(
      body: Row(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value, 0),
                child: child,
              );
            },
            child: Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.indigo.shade800,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(12, 16),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Encabezado del menú
                  Container(
                    height: 150,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(26),
                        bottomRight: Radius.circular(26),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: Image.asset('assets/images/logo_jmas_sf.png'),
                        ),
                        const SizedBox(height: 10),
                        if (userName != null)
                          Text(
                            userName!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                      ],
                    ),
                  ),
                  // Contenido del menú con scroll
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Elementos del menú
                          CustomListTile(
                            title: 'Orden de Servicio',
                            icon: Icon(Icons.home, color: Colors.white),
                            onTap: () => _navigateTo('addOrdenServicio'),
                          ),
                          CustomListTile(
                            title: 'Lista Orden Servicio',
                            icon: Icon(
                              Icons.list_alt_outlined,
                              color: Colors.white,
                            ),
                            onTap: () => _navigateTo('listOrdenServicio'),
                          ),
                          CustomListTile(
                            title: 'Tipo de Servicios',
                            icon: Icon(
                              Icons.tour_outlined,
                              color: Colors.white,
                            ),
                            onTap: () => _navigateTo('listTipoProblema'),
                          ),
                          CustomListTile(
                            title: 'Medios',
                            icon: Icon(
                              Icons.dark_mode_outlined,
                              color: Colors.white,
                            ),
                            onTap: () => _navigateTo('listMedios'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Logout
                  ListTile(
                    title: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent.shade400),
                        const SizedBox(width: 8),
                        Text(
                          'Salir',
                          style: TextStyle(
                            color: Colors.redAccent.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    onTap: _logOut,
                  ),
                ],
              ),
            ),
          ),

          // Contenido principal
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: Center(child: _currentPage),
            ),
          ),
        ],
      ),
    );
  }
}
