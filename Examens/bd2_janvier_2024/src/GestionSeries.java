import java.sql.*;
import java.util.Scanner;

public class GestionSeries {
    private Connection conn = null;
    private PreparedStatement listeSeries;
    public GestionSeries() {
        String url = "jdbc:postgresql://localhost:****/postgres" + "?user=****&password=*****"; // À remplacer
        // String url = "jdbc:postgresql://***.**.*.*:****/___ + "?user=____&password=____"; // @ School
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        try {
            conn=DriverManager.getConnection(url);
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
        try {
            listeSeries = conn.prepareStatement("SELECT code, nbre_etudiants" + " FROM examen.vue WHERE bloc = ?");

        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }

    private void listeSeries(Integer choixBloc) {
        try {
            listeSeries.setInt(1,choixBloc);
            try (ResultSet rs=listeSeries.executeQuery()) {
                while(rs.next()) {
                    System.out.println("Série "+rs.getString(1) + " : " + rs.getInt(2) + " étudiant(s)");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void close() {
        try {
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public static void main(String[] args) {
        GestionSeries gs = new GestionSeries();
        Scanner s = new Scanner(System.in);
        System.out.println("Choisissez le bloc :");
        Integer bloc = s.nextInt();
        gs.listeSeries(bloc);
        gs.close();
    }
}
