import java.sql.*;
import java.util.Scanner;

public class GestionConcerts {
    private Connection conn = null;
    private PreparedStatement ps;

    public GestionConcerts() {
        String url = "jdbc:postgresql://localhost:****/postgres" + "?user=postgres&password=*****";
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        try {
            conn = DriverManager.getConnection(url);
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.out.println(e.getMessage());
            System.exit(1);
        }
        try {
            ps = conn.prepareStatement("SELECT * FROM examen.voir_concerts_artiste WHERE artiste = ?");
        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }

    public void voirConcertsArtiste(String artiste) {
        try {
            ps.setString(1, artiste);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    System.out.println(rs.getString(1));
                    System.out.println(rs.getString(2));
                    System.out.println(rs.getString(3));
                    System.out.println();
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public static void main (String[] args) {
        GestionConcerts g = new GestionConcerts();
        Scanner s = new Scanner(System.in);
        System.out.println("Introduisez le nom de l'artiste : ");
        String artiste = s.nextLine();
        g.voirConcertsArtiste(artiste);
    }
}