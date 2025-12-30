#include <iostream>
using namespace std;

class Node {
public:
  int data;
  Node *prev;
  Node *next;

  Node(int value) {
    data = value;
    prev = nullptr;
    next = nullptr;
  }
};

int main() {
  // Create the first node (head of the list)
  Node *head = new Node(10);

  // Create and link the second node
  head->next = new Node(20);
  head->next->prev = head;

  // Create and link the third node
  head->next->next = new Node(30);
  head->next->next->prev = head->next;

  // Create and link the fourth node
  head->next->next->next = new Node(40);
  head->next->next->next->prev = head->next->next;

  // Traverse the list forward and print elements
  Node *temp = head;
  while (temp != nullptr) {
    cout << temp->data;
    if (temp->next != nullptr) {
      cout << " <-> ";
    }
    temp = temp->next;
  }

  return 0;
}
