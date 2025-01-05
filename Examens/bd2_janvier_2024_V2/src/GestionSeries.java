import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

public class GestionSeries {
    private String url="jdbc:postgresql://******:****/postgres" +
            "?user=*****&password=*****";
    private PreparedStatement vue;
    private Connection conn=null;
    public GestionSeries() {
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
            vue = conn.prepareStatement("SELECT code, nbre_etudiants" +
                            " FROM examen.vue" +
                            " WHERE bloc = ? " +
                    "ORDER BY nbre_etudiants DESC");
        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }
    private void vue(Integer bloc) {
        try {
            vue.setInt(1, bloc);
            try (ResultSet rs = vue.executeQuery()) {
                while(rs.next()) {
                    System.out.println("Série "+rs.getString(1) + " : " +rs.getInt(2) + " étudiant(s)");
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
        Scanner scanner = new Scanner(System.in);
        System.out.print("Entrez le bloc : ");
        Integer bloc = scanner.nextInt();
        System.out.println();
        gs.vue(bloc);
        gs.close();
    }
}
