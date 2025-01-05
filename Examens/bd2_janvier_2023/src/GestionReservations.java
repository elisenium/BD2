import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

public class GestionReservations {
    private String url="jdbc:postgresql://*****:****/****" +
            "?user=*****&password=******";
    private PreparedStatement vue;
    private Connection conn=null;
    public GestionReservations() {
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
            vue=
                    conn.prepareStatement("SELECT code, nom_exam, date_exam, nbre_locaux" +
                            " FROM examen.vue" + " WHERE bloc = ? " + "ORDER BY date_exam");

        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }
    private void vue(Integer bloc) {
        try {
            vue.setInt(1,bloc);
            try (ResultSet rs=vue.executeQuery()) {
                while(rs.next()) {
                    System.out.println(rs.getString(1) + " " + rs.getString(2) + " (" + rs.getDate(3) + ") : " + rs.getInt(4) + " locaux");
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
        GestionReservations gr = new GestionReservations();
        Scanner scanner = new Scanner(System.in);
        System.out.print("Entrez le bloc : ");
        int bloc = scanner.nextInt();
        System.out.println();
        gr.vue(bloc);
        gr.close();
    }
}
